class Reciter {
  final String name;
  final String id;
  final int bitrate;
  const Reciter({required this.name, required this.id, this.bitrate = 128});
}

const List<Reciter> availableReciters = [
  Reciter(name: 'Mishary Rashid Alafasy', id: 'ar.alafasy', bitrate: 128),
  Reciter(name: 'Abu Bakr Al-Shatri', id: 'ar.shaatree', bitrate: 128),
  Reciter(
    name: 'Abdurrahmaan As-Sudais',
    id: 'ar.abdurrahmaansudais',
    bitrate: 192,
  ),
  Reciter(name: 'Maher Al-Muaiqly', id: 'ar.mahermuaiqly', bitrate: 128),
  Reciter(name: 'AbdulBaset AbdulSamad', id: 'ar.abdulsamad', bitrate: 64),
  Reciter(name: 'Hani Ar-Rifai', id: 'ar.hanirifai', bitrate: 192),
  Reciter(name: 'Muhammad Ayyoub', id: 'ar.muhammadayyoub', bitrate: 128),
];
