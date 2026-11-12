// Form constants matching Nagarsevak-Managment ComplaintForm.tsx and PersonalRequestForm.tsx

const Map<String, List<String>> kSocietiesByWard = {
  'Sector 5': [
    'SHANTIDOOT APT', 'OMKAR CHS', 'MAYNAK CHS', 'VANRAI APT', 'PRATHAMESH CHS', 
    'SHIVKRUPA APT', 'SAHAYOG CHS', 'SUYOG CHS', 'AASHIYANA', 'MORYA', 
    'PANCHSHEEL ARKED', 'BALAJI SOCIETY', 'PANCHSHEEL PLAZA'
  ],
  'Sector 6': [
    'EXCEL RESIDENCY', 'GHARKUL CHS', 'ROOPMAYA CHS', 'YASH RESIDANCY', 'MANAS CHS', 
    'MERCURY', 'DYNASTY', 'EXCEL PARK', 'MADHURI', 'SHIV SHANKAR CHS', 
    'BLACK SMITH TOWER', 'ARIHANT CHS', 'UMAGEETA', 'MANGAL MOORTHY', 
    'SANSKRUTI NAVAVIDYUT CHS', 'SUKHMANI CHS', 'PARIJAT DHRUV CHS', 'MIHIR TOWER', 
    'CHINMAY CHS', 'CELEBRATION CHS', 'SWANAND', 'MADHUBAN CHS', 'VENUS CHS', 
    'RAJSTHAN CHS', 'SHREE SWAMI DARSHAN', 'RUSHI CHS', 'GOODWILL RESIDENCY', 
    'SWAMI ASHIRWAD', 'AMRIT CHS', 'JUPITER CHS', 'GREEN PARK', 'SHREE SWAMI CHARAN', 
    'SAI RAJ'
  ],
  'Sector 7': [
    'SHIVSHANKAR PLAZA II', 'AJAY CHS', 'RAKESH PARK', 'DEVIPRASAD CHS',
    'NEW BOMBAY SAPHALY', 'SHIVESH EMERALD', 'PANCHASHIL', 'KARAN CHS', 'GEETSONALI CHS',
    'SUNDARBAN', 'RUDRAKSHA', 'LOTUS CHS', 'PAMSPRING', 'SHREE DURGA', 
    'DNYANDEEP DARSHAN', 'VISHAL', 'NAYAN TARA', 'SUPERIOR MICRON', 'OM ARCHADE',
    'SUPERIOUR (UNDER CONSTRUCTION)'
  ],
  'Sector 8 - Saibaba Temple Area': [
    'SOMESHWAR TOWER', 'DATTATREY MAHARAJ', 'KALPRATNA', 'SUKH SHANTI', 'MARUTI ENCLAVE',
    'EDEN PARK', 'NEW EKTA', 'SHREE RAM DARSHAN', 'ALANKAR', 'BINDAL',
    'AGRAWAL PARK', 'KRISHNA KANIYA', 'SWAMI NAVSHARANAM', 'SHREE DURGA PRASAD',
    'MAULI KRUPA', 'APURVA', 'SHREE SWAMI SADGURU', 'KASTURI TOWER', 'KASTURI GARDAN',
    'NEW CONSTRUCTION', 'SAMTA', 'EDEN TOWER', 'SAI BABA TEMPLE'
  ],
  'Sector 8 - Deva Bunglow Back Side Area': [
    'GURUKUL', 'SHASHWAT', 'EKVIRA DARSHAN', 'YASH PARADISE', 'SHUBHARAMBH',
    'BRAMHRAJ', 'SAI PRERNA', 'SHREE SWAMI SAMARTH', 'SAI SABURI', 'SHREE SIDDHIVINAYAK',
    'LAXMI SAWALI', 'JYOTI', 'OPEN PLOT', 'BHAJI MARKET', 'YOGESH', 'SILVIYA',
    'VASTU VRUNDAVAN', 'SAI', 'GANESH', 'MAJJUDDIN SCHOOL', 'RAJGOPAL', 'RAJLAXMI',
    'KAMTI PLAZA', 'SAI SHRADDHA', 'MORESHWAR', 'VARDVINAYAK', 'SHRIMAN', 'SHRIKRUPA',
    'KRISHNA HIGHTS', 'SUSHILA', 'BLOSOM', 'SHREEJI DHAM'
  ],
  'Sector 9': [
    'bramharaj annex', 'swami Samarth chs', 'Shanti villa', 'ananta niwas', 'parvati apt',
    'janabai apt', 'vighnaharta apt', 'mankubai apt', 'shantai niwas', 'manjula apt',
    'radhe shyam apt', 'Vighnahar chs', 'divyal chs', 'siddhivinayak chs', 'sea side chs',
    'mangalmurti apt', 'shree sai apt', 'jai kalika apt', 'vitthal niwas', 'balkrishna apt',
    'Pratham Plaza', 'Kasturi Valley', 'Shri Krishna Vaibhav', 'Krishna chs', 'Matruchaya',
    'Sai Sharan', 'sea Sai chs', 'Aayush Apt', 'Vinashree', 'Sachidanand',
    'Sai Satish', 'Balaji', 'Vinit', 'Tulsi', 'Radha Krishna',
    'Sai Apartment', 'Tukaram niwas', 'narmada apt', 'nike height', 'Gangaram plaza',
    'nice mension', 'balaji park', 'gajanan villla', 'pandurang apt', 'vitthal keni niwas',
    'akhadya villa', 'sitaram park', 'posha niwas', 'siddhu keni niwas', 'venubai rama niwas',
    'ganpat niwas', 'laxmi niwas', 'Ambo niwas', 'bapu niwas', 'mukunda niwas',
    'vasanti niwas', 'Heena Mension', 'Riddhi', 'Sadguru', 'Shravan',
    'Matruchaya (2)', 'Shraddha Neha', 'Shree Vighnahar', 'Chintamani Chs', 'Sai Bramhan',
    'Shakti Krupa', 'Shri Prasad', 'Abhishek', 'Ashirwad', 'Shiv Parvati',
    'Savitri', 'Sayli', 'mansi chs', 'C K P sadan', 'varad ashish chs',
    'Ratna Apt', 'kulswamini niwas', 'vasanti vitthal niwas', 'vaishnavi apt', 'Diva gaon 1',
    'chagan bhagirath patil niwas', 'madhvi house', 'etwar bapu patil niwas', 'hirubai patil niwas', 'maruti bhawan niwas',
    'Kunal chs', 'Matoshree chs', 'sai Sagar chs', 'Airoli Sai shradha chs', 'Sai deep chs',
    'Vishwaspatra chs', 'shrawan chs', 'Kajal', 'Sai Prasad', 'Sai Vilas',
    'Sai Apartment (2)', 'My choice', 'Om Shrushti Villa', 'Chinmay', 'Sai Mauli',
    'Sai Saily', 'Shri Sakshi', 'Ram Krishna', 'Icchapurti', 'Suman',
    'Space Plaza', 'My Apartment', 'Vishnu'
  ],
  'Sector 9 - Bhavani Mata Temple': [
    'GANESH', 'PRANAY', 'SHIVAM', 'PRATHMESH', 'SHREE PRASAD', 'RAM KRISHNA', 'OPEN PLOT',
    'SAI SATISH', 'SHREE SAKSHI', 'SHAKTI KRUPA', 'SAI SAILY', 'SAI BRAMHAN', 'VEENA CHS',
    'SAI MAULI', 'BHAVANI MATA MANDIR', 'OPEN MAIDAN (CONTAINER)', 'AAYUSH APARTMENT',
    'SIDDHIVINAYAK CHS', 'SIDDHI ARCADE', 'BALAJI'
  ],
  'Sector 9 - Ganpati Bappa Chauk To D Mart': [
    'KAJAL', 'OM SHRUSHTI VILLA', 'SHRADDHA NEHA', 'SAI SHARAN', 'MATRUCHAYA', 
    'ICCHAPURTI', 'ABHISHEK', 'OPEN PLOT', 'CHINTAMANI', 'CONSTRUCTION', 
    'SAI APARTMENT', 'MY APARTMENT', 'SAVITRI', 'RADHA KRISHNA', 'TULSI', 
    'SHIV PARVATI', 'SPACE PLAZA', 'SUMAN', 'ASHIRWAD', 'VINIT', 'KRISHNA', 
    'KRISHNA CHS', 'SHREE KRISHNA VAIBHAV', 'KASTURI VALLY', 'PRATHAM PLAZA', 
    'SADGURU', 'HEENA MENSION', 'RIDDHI', 'SHRAVAN', 'SAI PRASAD', 'SAI VILAS', 
    'MY CHOICE'
  ],
  'Sector 9 - Saily Society': [
    'SOHAM', 'PRERNA CHAYA', 'RADHA KRISHNA', 'KALPATARU', 'GURUDEV', 'OPEN',
    'SAI VIRAJ', 'SAPTAGIRI', 'GIRNAR', 'ADITI', 'NAV ARIHANT', 'SAI DRUSHTI',
    'NEW OMKAR', 'EVERGREEN', 'SACCHIDANAND', 'VISHNU', 'SAILY', 'HOLI MAIDAN',
    'SAI APARTMENT', 'MANGAL MURTI', 'JAI KALIKA'
  ],
  'Sector 9 - Sane Guruji Mandal': [
    'VIGHNAHAR', 'DIVYAL', 'SIDDHIVINAYAK', 'SHREE SAI', 'BALAJI PARK',
    'CHINMAY', 'SHANKAR KRUPA', 'VIGHNESHWAR', 'OPEN'
  ],
  'Sector 10': [
    'SHIVDARSHAN', 'SWARAJYA', 'JAI OMKAR', 'SHRE GANESH KRUPA', 'TAPSYA',
    'SHIVNERI', 'SAGARDARSHAN', 'SUKHSHANTI', 'MANGAL DARSHAN', 'OMKAR',
    'BRIDGEVIEW', 'SAGAR', 'PRATIK'
  ],
  'Sector 14': [
    'Ajantha Sea Breeze', 'Sunteck Signia Oceans', 'Bhumikocolosa - 2',
    'Matoshree Apt', 'Purna CHS', 'Prabhat Kiran CHS', 'Lake View CHS',
    'Kalptaru CSH', 'MangalDeep CHS'
  ],
  'Sector 15': [
    'Dakshina CHS', 'Akshay CHS', 'Vaitrna CHS', 'Shree Samrth CHS', 'Panchtara CHS',
    'Aashirvad CHS', 'Suprabhat CHS', 'Triveni CHS', 'Ashtavinayak CHS', 'Saptshrungi CHS',
    'Navjivan CHS', 'Puja CHS', 'Darshan CHS', 'Shiv Shakti CHS', 'Shri Gajajnan CHS',
    'Om Sai CHS', 'Himalay CHS', 'Amey CHS'
  ],
};

const List<String> kWardsList = [
  'Sector 5',
  'Sector 6',
  'Sector 7',
  'Sector 8 - Saibaba Temple Area',
  'Sector 8 - Deva Bunglow Back Side Area',
  'Sector 9',
  'Sector 9 - Bhavani Mata Temple',
  'Sector 9 - Ganpati Bappa Chauk To D Mart',
  'Sector 9 - Saily Society',
  'Sector 9 - Sane Guruji Mandal',
  'Sector 10',
  'Sector 14',
  'Sector 15',
  'Out of Ward',
];

class CategoryOption {
  final String key;
  final String en;
  final String mr;

  const CategoryOption({
    required this.key,
    required this.en,
    required this.mr,
  });
}

const List<CategoryOption> kComplaintCategories = [
  CategoryOption(key: 'Cleaning', en: 'Cleaning / Garbage', mr: 'स्वच्छता / कचरा'),
  CategoryOption(key: 'Water', en: 'Water Supply', mr: 'पाणी पुरवठा'),
  CategoryOption(key: 'Road', en: 'Road / Potholes', mr: 'रस्ते / खड्डे'),
  CategoryOption(key: 'Drainage', en: 'Drainage', mr: 'ड्रेनेज (गटार)'),
  CategoryOption(key: 'StreetLight', en: 'Street Light', mr: 'पथदिवे'),
  CategoryOption(key: 'SelfIdentified', en: 'Ward Problem', mr: 'प्रभागातील समस्या'),
  CategoryOption(key: 'Other', en: 'Other', mr: 'इतर'),
];

const List<CategoryOption> kPersonalRequestCategories = [
  CategoryOption(key: 'Admission', en: 'Education / Admission', mr: 'शिक्षण / प्रवेश मदत'),
  CategoryOption(key: 'Medical', en: 'Medical Help', mr: 'वैद्यकीय मदत'),
  CategoryOption(key: 'Financial', en: 'Financial Help', mr: 'आर्थिक मदत'),
  CategoryOption(key: 'Help', en: 'Help', mr: 'मदत'),
  CategoryOption(key: 'Personal Help', en: 'Personal Help', mr: 'वैयक्तिक मदत'),
];

