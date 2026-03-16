///|
/// Imported MIDI data parsed from a .mid file.
/// Sounds are pre-scheduled with absolute start times and durations in ms.
pub(all) struct ImportedMidi {
  melody_sounds : Array[@music.ScheduledSound]
  comping_sounds : Array[@music.ScheduledSound]
  bass_sounds : Array[@music.ScheduledSound]
  drum_sounds : Array[@music.ScheduledSound]
  bpm : Int?
  key : @music.KeySignature?
  time_sig : @music.TimeSignature?
  measure_count : Int?
}

///|
priv struct OpenNote {
  ch : Int
  pitch : Int
  start_tick : Int
}

///|
fn read_u32(bytes : Array[Int], pos : Int) -> Int {
  if pos + 3 >= bytes.length() {
    return 0
  }
  (bytes[pos] << 24) |
  (bytes[pos + 1] << 16) |
  (bytes[pos + 2] << 8) |
  bytes[pos + 3]
}

///|
fn read_u16(bytes : Array[Int], pos : Int) -> Int {
  if pos + 1 >= bytes.length() {
    return 0
  }
  (bytes[pos] << 8) | bytes[pos + 1]
}

///|
fn read_vlq(bytes : Array[Int], pos : Ref[Int]) -> Int {
  let mut result = 0
  while pos.val < bytes.length() {
    let b = bytes[pos.val]
    pos.val = pos.val + 1
    result = (result << 7) | (b & 0x7F)
    if (b & 0x80) == 0 {
      break
    }
  }
  result
}

///|
fn sf_to_key(sf_raw : Int) -> @music.KeySignature? {
  let sf = if sf_raw >= 128 { sf_raw - 256 } else { sf_raw }
  match sf {
    0 => Some(@music.KeySignature::from_root(@music.ChordRoot::C))
    1 => Some(@music.KeySignature::from_root(@music.ChordRoot::G))
    2 => Some(@music.KeySignature::from_root(@music.ChordRoot::D))
    3 => Some(@music.KeySignature::from_root(@music.ChordRoot::A))
    4 => Some(@music.KeySignature::from_root(@music.ChordRoot::E))
    5 => Some(@music.KeySignature::from_root(@music.ChordRoot::B))
    6 => Some(@music.KeySignature::from_root(@music.ChordRoot::FSharp))
    -1 => Some(@music.KeySignature::from_root(@music.ChordRoot::F))
    -2 => Some(@music.KeySignature::from_root(@music.ChordRoot::ASharp))
    -3 => Some(@music.KeySignature::from_root(@music.ChordRoot::DSharp))
    -4 => Some(@music.KeySignature::from_root(@music.ChordRoot::GSharp))
    -5 => Some(@music.KeySignature::from_root(@music.ChordRoot::CSharp))
    _ => None
  }
}

///|
/// Remove first open note matching (ch, pitch) and return its start_tick.
fn pop_open_note(open_notes : Array[OpenNote], ch : Int, pitch : Int) -> Int? {
  for i in 0..<open_notes.length() {
    let n = open_notes[i]
    if n.ch == ch && n.pitch == pitch {
      let last = open_notes.length() - 1
      if i != last {
        open_notes[i] = open_notes[last]
      }
      match open_notes.pop() {
        Some(_) => return Some(n.start_tick)
        None => return None
      }
    }
  }
  None
}

///|
fn push_sound(
  melody : Array[@music.ScheduledSound],
  comping : Array[@music.ScheduledSound],
  bass : Array[@music.ScheduledSound],
  drums : Array[@music.ScheduledSound],
  ch : Int,
  pitch : Int,
  start_ms : Double,
  dur_ms : Double,
) -> Unit {
  match @music.MidiNumber::new(pitch) {
    None => ()
    Some(m) => {
      let sound = @music.ScheduledSound::{
        sound_event: @music.Note(midi=m, duration=@music.NoteDuration::Quarter),
        duration: @music.Duration::from_milliseconds(dur_ms),
        start_time: @music.Duration::from_milliseconds(start_ms),
        tone_origin: Some(@music.ToneOrigin::Imported),
      }
      match ch {
        0 => melody.push(sound)
        1 => comping.push(sound)
        2 => bass.push(sound)
        9 => drums.push(sound)
        _ => ()
      }
    }
  }
}

///|
/// Number of data bytes for a MIDI channel message type (upper nibble).
fn midi_data_bytes(msg_type : Int) -> Int {
  match msg_type {
    0x8 | 0x9 | 0xA | 0xB | 0xE => 2
    _ => 1
  }
}

///|
/// Decode a Standard MIDI File (SMF) from a byte array.
/// Returns ImportedMidi with sounds routed by channel:
///   ch0 → melody, ch1 → comping, ch2 → bass, ch9 → drums
/// Returns None if the file is not a valid SMF format 0 or 1.
pub fn decode_midi(bytes : Array[Int]) -> ImportedMidi? {
  // Verify MThd magic (4D 54 68 64)
  if bytes.length() < 14 {
    return None
  }
  if bytes[0] != 0x4D ||
    bytes[1] != 0x54 ||
    bytes[2] != 0x68 ||
    bytes[3] != 0x64 {
    return None
  }
  let format = read_u16(bytes, 8)
  let num_tracks = read_u16(bytes, 10)
  let division = read_u16(bytes, 12)
  // Reject SMPTE timecode (bit 15 set) or unsupported format
  if (division & 0x8000) != 0 || format > 1 || division == 0 {
    return None
  }
  let tpq = division.to_double()
  // Locate MTrk chunk positions
  let track_starts : Array[Int] = []
  let track_lengths : Array[Int] = []
  let mut scan_pos = 14
  while scan_pos + 8 <= bytes.length() && track_starts.length() < num_tracks {
    let magic = read_u32(bytes, scan_pos)
    let tlen = read_u32(bytes, scan_pos + 4)
    if magic == 0x4D54726B { // "MTrk"
      track_starts.push(scan_pos + 8)
      track_lengths.push(tlen)
    }
    scan_pos = scan_pos + 8 + tlen
  }
  // Pass 1: collect meta events (tempo, key signature, time signature)
  let mut tempo_us = 500000 // default: 120 BPM
  let mut found_key = false
  let mut found_time = false
  let mut key_sig : @music.KeySignature? = None
  let mut time_sig : @music.TimeSignature? = None
  for ti in 0..<track_starts.length() {
    let t_start = track_starts[ti]
    let t_end = t_start + track_lengths[ti]
    let p : Ref[Int] = { val: t_start }
    let mut running = 0
    while p.val < t_end {
      let _ = read_vlq(bytes, p)
      if p.val >= t_end {
        break
      }
      let sb = bytes[p.val]
      if sb == 0xFF {
        p.val = p.val + 1
        if p.val >= t_end {
          break
        }
        let mtype = bytes[p.val]
        p.val = p.val + 1
        let mlen = read_vlq(bytes, p)
        let mstart = p.val
        match (mtype, mlen) {
          (0x51, 3) => {
            let us = (bytes[mstart] << 16) |
              (bytes[mstart + 1] << 8) |
              bytes[mstart + 2]
            if us > 0 {
              tempo_us = us
            }
          }
          (0x58, 4) =>
            if not(found_time) {
              found_time = true
              let nn = bytes[mstart]
              let dd = bytes[mstart + 1]
              time_sig = Some(@music.TimeSignature::{
                numerator: nn,
                denominator: 1 << dd,
              })
            }
          (0x59, 2) =>
            if not(found_key) {
              found_key = true
              key_sig = sf_to_key(bytes[mstart])
            }
          _ => ()
        }
        p.val = mstart + mlen
        running = 0
      } else if sb == 0xF0 || sb == 0xF7 {
        p.val = p.val + 1
        let slen = read_vlq(bytes, p)
        p.val = p.val + slen
        running = 0
      } else if (sb & 0x80) != 0 {
        running = sb
        p.val = p.val + 1
        let skip = midi_data_bytes((sb >> 4) & 0x0F)
        p.val = p.val + skip
      } else if running != 0 {
        let skip = midi_data_bytes((running >> 4) & 0x0F)
        p.val = p.val + skip
      } else {
        break
      }
    }
  }
  let bpm_val = 60000000 / tempo_us
  let tus = tempo_us.to_double()
  let melody : Array[@music.ScheduledSound] = []
  let comping : Array[@music.ScheduledSound] = []
  let bass : Array[@music.ScheduledSound] = []
  let drums : Array[@music.ScheduledSound] = []
  let open_notes : Array[OpenNote] = []
  // Pass 2: collect note events and convert tick timing to milliseconds
  for ti in 0..<track_starts.length() {
    let t_start = track_starts[ti]
    let t_end = t_start + track_lengths[ti]
    let p : Ref[Int] = { val: t_start }
    let mut running = 0
    let mut tick = 0
    while p.val < t_end {
      tick = tick + read_vlq(bytes, p)
      if p.val >= t_end {
        break
      }
      let sb = bytes[p.val]
      if sb == 0xFF {
        p.val = p.val + 1
        if p.val >= t_end {
          break
        }
        p.val = p.val + 1 // skip meta type
        let mlen = read_vlq(bytes, p)
        p.val = p.val + mlen
        running = 0
      } else if sb == 0xF0 || sb == 0xF7 {
        p.val = p.val + 1
        let slen = read_vlq(bytes, p)
        p.val = p.val + slen
        running = 0
      } else {
        let status = if (sb & 0x80) != 0 {
          running = sb
          p.val = p.val + 1
          sb
        } else if running != 0 {
          running
        } else {
          break
        }
        let mtype = (status >> 4) & 0x0F
        let ch = status & 0x0F
        match mtype {
          0x9 => {
            if p.val + 2 > t_end {
              break
            }
            let pitch = bytes[p.val]
            let vel = bytes[p.val + 1]
            p.val = p.val + 2
            if vel > 0 {
              open_notes.push(OpenNote::{ ch, pitch, start_tick: tick })
            } else {
              // Note On with velocity 0 = Note Off
              match pop_open_note(open_notes, ch, pitch) {
                None => ()
                Some(st) => {
                  let dur = (tick - st).to_double() * tus / tpq / 1000.0
                  let start = st.to_double() * tus / tpq / 1000.0
                  push_sound(
                    melody, comping, bass, drums, ch, pitch, start, dur,
                  )
                }
              }
            }
          }
          0x8 => {
            if p.val + 2 > t_end {
              break
            }
            let pitch = bytes[p.val]
            p.val = p.val + 2
            match pop_open_note(open_notes, ch, pitch) {
              None => ()
              Some(st) => {
                let dur = (tick - st).to_double() * tus / tpq / 1000.0
                let start = st.to_double() * tus / tpq / 1000.0
                push_sound(melody, comping, bass, drums, ch, pitch, start, dur)
              }
            }
          }
          0xA | 0xB | 0xE => if p.val + 2 <= t_end { p.val = p.val + 2 }
          _ => if p.val + 1 <= t_end { p.val = p.val + 1 }
        }
      }
    }
  }
  // Compute measure count from total sound duration
  let all_sounds = melody + comping + bass + drums
  let max_end_ms = all_sounds.fold(init=0.0, fn(acc, s) {
    let end_ms = s.start_time.to_milliseconds() + s.duration.to_milliseconds()
    if end_ms > acc {
      end_ms
    } else {
      acc
    }
  })
  let beats_per_meas = match time_sig {
    Some(ts) => ts.beats_per_measure()
    None => 4.0
  }
  let ms_per_meas = @music.ms_per_measure(
    bpm_val,
    beats_per_measure=beats_per_meas,
  )
  let measure_count_val = if ms_per_meas > 0.0 && max_end_ms > 0.0 {
    let raw = max_end_ms / ms_per_meas
    let floored = raw.to_int()
    Some(if raw > floored.to_double() { floored + 1 } else { floored })
  } else {
    None
  }
  sort_by_start_time(melody)
  sort_by_start_time(comping)
  sort_by_start_time(bass)
  sort_by_start_time(drums)
  Some(ImportedMidi::{
    melody_sounds: melody,
    comping_sounds: comping,
    bass_sounds: bass,
    drum_sounds: drums,
    bpm: Some(bpm_val),
    key: key_sig,
    time_sig,
    measure_count: measure_count_val,
  })
}

///|
fn sort_by_start_time(sounds : Array[@music.ScheduledSound]) -> Unit {
  let n = sounds.length()
  for i in 1..<n {
    let key = sounds[i]
    let key_ms = key.start_time.to_milliseconds()
    let mut j = i - 1
    while j >= 0 && sounds[j].start_time.to_milliseconds() > key_ms {
      sounds[j + 1] = sounds[j]
      j = j - 1
    }
    sounds[j + 1] = key
  }
}
