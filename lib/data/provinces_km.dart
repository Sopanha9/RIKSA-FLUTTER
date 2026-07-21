/// 25 Cambodian provinces with Khmer and English names.
///
/// Use for the province picker after language selection.
/// Compare later by either name:
///   if (province.km == 'សៀមរាប') { ... }
///   if (province.en == 'Siem Reap') { ... }
class Province {
  final String km;
  final String en;

  const Province({required this.km, required this.en});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Province && km == other.km && en == other.en;

  @override
  int get hashCode => Object.hash(km, en);
}

const List<Province> provincesKm = [
  Province(km: 'បន្ទាយមានជ័យ', en: 'Banteay Meanchey'),
  Province(km: 'បាត់ដំបង', en: 'Battambang'),
  Province(km: 'កំពង់ចាម', en: 'Kampong Cham'),
  Province(km: 'កំពង់ឆ្នាំង', en: 'Kampong Chhnang'),
  Province(km: 'កំពង់ស្ពឺ', en: 'Kampong Speu'),
  Province(km: 'កំពង់ធំ', en: 'Kampong Thom'),
  Province(km: 'កំពត', en: 'Kampot'),
  Province(km: 'កណ្ដាល', en: 'Kandal'),
  Province(km: 'កែប', en: 'Kep'),
  Province(km: 'កោះកុង', en: 'Koh Kong'),
  Province(km: 'ក្រចេះ', en: 'Kratié'),
  Province(km: 'មណ្ឌលគិរី', en: 'Mondulkiri'),
  Province(km: 'ឧត្តរមានជ័យ', en: 'Oddar Meanchey'),
  Province(km: 'ប៉ៃលិន', en: 'Pailin'),
  Province(km: 'ភ្នំពេញ', en: 'Phnom Penh'),
  Province(km: 'ព្រះសីហនុ', en: 'Preah Sihanouk'),
  Province(km: 'ព្រះវិហារ', en: 'Preah Vihear'),
  Province(km: 'ព្រៃវែង', en: 'Prey Veng'),
  Province(km: 'ពោធិ៍សាត់', en: 'Pursat'),
  Province(km: 'រតនគិរី', en: 'Ratanakiri'),
  Province(km: 'សៀមរាប', en: 'Siem Reap'),
  Province(km: 'ស្ទឹងត្រែង', en: 'Stung Treng'),
  Province(km: 'ស្វាយរៀង', en: 'Svay Rieng'),
  Province(km: 'តាកែវ', en: 'Takéo'),
  Province(km: 'ត្បូងឃ្មុំ', en: 'Tbong Khmum'),
];