/// Liste complète des zones de Côte d'Ivoire
/// Format: "Ville, Département, Région"
/// Organisée par région en ordre alphabétique, sans doublons
library;

class ZonesCoteIvoire {
  static final List<String> zones = [
    // DISTRICT AUTONOME D'ABIDJAN
    'Abobo, Abobo, Abidjan',
    'Adjamé, Adjamé, Abidjan',
    'Anyama, Anyama, Abidjan',
    'Attécoubé, Attécoubé, Abidjan',
    'Bingerville, Bingerville, Abidjan',
    'Cocody, Cocody, Abidjan',
    'Koumassi, Koumassi, Abidjan',
    'Marcory, Marcory, Abidjan',
    'Plateau, Plateau, Abidjan',
    'Port-Bouët, Port-Bouët, Abidjan',
    'Songon, Songon, Abidjan',
    'Treichville, Treichville, Abidjan',
    'Yopougon, Yopougon, Abidjan',
    // Villages proches d'Abidjan
    'Abobo-Gare, Abobo, Abidjan',
    'Adjamé-Williamsville, Adjamé, Abidjan',
    'Angré, Cocody, Abidjan',
    'Riviera, Cocody, Abidjan',
    'Deux-Plateaux, Cocody, Abidjan',

    // DISTRICT AUTONOME DE YAMOUSSOUKRO
    'Yamoussoukro, Yamoussoukro, Yamoussoukro',
    'Attiégouakro, Yamoussoukro, Yamoussoukro',
    // Villages proches de Yamoussoukro
    'Kossou, Yamoussoukro, Yamoussoukro',
    'N\'Gattakro, Yamoussoukro, Yamoussoukro',
    'Lolobo, Yamoussoukro, Yamoussoukro',
    'Kokrenou, Yamoussoukro, Yamoussoukro',
    'Diacohou, Yamoussoukro, Yamoussoukro',

    // RÉGION AGNÉBY-TIASSA
    'Agboville, Agboville, Agnéby-Tiassa',
    'Azaguié, Agboville, Agnéby-Tiassa',
    'Rubino, Agboville, Agnéby-Tiassa',
    'Céchi, Sikensi, Agnéby-Tiassa',
    'Sikensi, Sikensi, Agnéby-Tiassa',
    'Taabo, Taabo, Agnéby-Tiassa',
    'Tiassalé, Tiassalé, Agnéby-Tiassa',
    'N\'Douci, Tiassalé, Agnéby-Tiassa',
    // Villages proches d'Agboville
    'Oress-Krobou, Agboville, Agnéby-Tiassa',
    'Attoutou, Agboville, Agnéby-Tiassa',
    'Bodo, Agboville, Agnéby-Tiassa',
    'Guessiguié, Agboville, Agnéby-Tiassa',
    'Offa, Agboville, Agnéby-Tiassa',

    // RÉGION BAFING
    'Koonan, Koonan, Bafing',
    'Touba, Touba, Bafing',
    'Booko, Touba, Bafing',
    'Guinteguela, Touba, Bafing',
    'Mahapleu, Touba, Bafing',
    'Ouaninou, Touba, Bafing',
    // Villages proches de Touba
    'Foungbesso, Touba, Bafing',
    'Borotou, Touba, Bafing',
    'Koro, Touba, Bafing',
    'Niéllé, Touba, Bafing',
    'Sokourala, Touba, Bafing',

    // RÉGION BAGOUÉ
    'Boundiali, Boundiali, Bagoué',
    'Ganaoni, Boundiali, Bagoué',
    'Kasséré, Boundiali, Bagoué',
    'Kouto, Kouto, Bagoué',
    'Tengréla, Tengréla, Bagoué',
    // Villages proches de Boundiali
    'Siempurgo, Boundiali, Bagoué',
    'Baya, Boundiali, Bagoué',
    'Débété, Boundiali, Bagoué',
    'Torkoro, Boundiali, Bagoué',
    'Gbon, Boundiali, Bagoué',

    // RÉGION BÉLIER
    'Didiévi, Didiévi, Bélier',
    'Raviart, Didiévi, Bélier',
    'Toumodi, Toumodi, Bélier',
    'Koffi-Amonkro, Toumodi, Bélier',
    // Villages proches de Toumodi
    'Kokumbo, Toumodi, Bélier',
    'Moronou, Toumodi, Bélier',
    'Angonda, Toumodi, Bélier',
    'Ayaou-Sran, Toumodi, Bélier',
    'Aouakro, Toumodi, Bélier',

    // RÉGION BÉRÉ
    'Béréby, Béréby, Béré',
    'Djidji, Béréby, Béré',
    'Gnagbodougnoa, Béréby, Béré',
    'Méagui, Méagui, Béré',
    'Soubré, Soubré, Béré',
    'Buyo, Soubré, Béré',
    'Grand-Zattry, Soubré, Béré',
    // Villages proches de Soubré
    'Gnamangui, Soubré, Béré',
    'Okrouyo, Soubré, Béré',
    'Yabayo, Soubré, Béré',
    'Dahiépa-Kéhi, Soubré, Béré',
    'Liliyo, Soubré, Béré',

    // RÉGION BOUNKANI
    'Bouna, Bouna, Bounkani',
    'Doropo, Doropo, Bounkani',
    'Nassian, Nassian, Bounkani',
    'Téhini, Téhini, Bounkani',
    // Villages proches de Bouna
    'Gogo, Bouna, Bounkani',
    'Ondefidouo, Bouna, Bounkani',
    'Kakpin, Bouna, Bounkani',
    'Bondo, Bouna, Bounkani',
    'Yondio, Bouna, Bounkani',

    // RÉGION CAVALLY
    'Blolequin, Blolequin, Cavally',
    'Guiglo, Guiglo, Cavally',
    'Kaadé, Guiglo, Cavally',
    'Taï, Taï, Cavally',
    'Toulépleu, Toulépleu, Cavally',
    'Zouan-Hounien, Zouan-Hounien, Cavally',
    'Banneu, Zouan-Hounien, Cavally',
    // Villages proches de Guiglo
    'Kahin, Guiglo, Cavally',
    'Péhé, Guiglo, Cavally',
    'Bounta, Guiglo, Cavally',
    'Dougroupalegnoa, Guiglo, Cavally',
    'Guessabo, Guiglo, Cavally',

    // RÉGION GBÊKÊ
    'Bassawa, Bassawa, Gbêkê',
    'Bouaké, Bouaké, Gbêkê',
    'Brobo, Brobo, Gbêkê',
    'Botro, Botro, Gbêkê',
    'Béoumi, Béoumi, Gbêkê',
    'Bodokro, Béoumi, Gbêkê',
    'Kondrobo, Béoumi, Gbêkê',
    'Sakassou, Sakassou, Gbêkê',
    'Diabo, Sakassou, Gbêkê',
    // Villages proches de Bouaké
    'Dar-es-Salam, Bouaké, Gbêkê',
    'Koko, Bouaké, Gbêkê',
    'Bamoro, Bouaké, Gbêkê',
    'Konankankro, Bouaké, Gbêkê',
    'Akpokro, Bouaké, Gbêkê',

    // RÉGION GBÔKLÉ
    'Fresco, Fresco, Gbôklé',
    'Dahiri, Fresco, Gbôklé',
    'Gbagbam, Fresco, Gbôklé',
    'Sassandra, Sassandra, Gbôklé',
    'Sago, Sassandra, Gbôklé',
    // Villages proches de Sassandra
    'Grihiri, Sassandra, Gbôklé',
    'Lobakuya, Sassandra, Gbôklé',
    'Dakpadou, Sassandra, Gbôklé',
    'San-Pédro, Sassandra, Gbôklé',
    'Gabiadji, Sassandra, Gbôklé',

    // RÉGION GÔH
    'Gagnoa, Gagnoa, Gôh',
    'Bayota, Gagnoa, Gôh',
    'Dignago, Gagnoa, Gôh',
    'Galébré, Gagnoa, Gôh',
    'Guibéroua, Gagnoa, Gôh',
    'Ouffoué-Kpatagouan, Gagnoa, Gôh',
    'Serihio, Gagnoa, Gôh',
    'Ouragahio, Ouragahio, Gôh',
    // Villages proches de Gagnoa
    'Dignago-Miambo, Gagnoa, Gôh',
    'Dahiepa, Gagnoa, Gôh',
    'Doussikro, Gagnoa, Gôh',
    'Oumé, Gagnoa, Gôh',
    'Bayota-Gare, Gagnoa, Gôh',

    // RÉGION GONTOUGO
    'Bondoukou, Bondoukou, Gontougo',
    'Goulia, Bondoukou, Gontougo',
    'Laoudi-Ba, Bondoukou, Gontougo',
    'Pinda-Boroko, Bondoukou, Gontougo',
    'Sorobango, Bondoukou, Gontougo',
    'Tabagne, Bondoukou, Gontougo',
    'Taoudi, Bondoukou, Gontougo',
    'Koun-Fao, Koun-Fao, Gontougo',
    'Sandégué, Sandégué, Gontougo',
    'Transua, Transua, Gontougo',
    // Villages proches de Bondoukou
    'Tangafla, Bondoukou, Gontougo',
    'Kouassi-Dattékro, Bondoukou, Gontougo',
    'Gouméré, Bondoukou, Gontougo',
    'Bondo, Bondoukou, Gontougo',
    'Sapli-Sépingo, Bondoukou, Gontougo',
    // Villages proches de Sorobango
    'Assuéfry, Bondoukou, Gontougo',
    'Yézimala, Bondoukou, Gontougo',
    'Tienkoikro, Bondoukou, Gontougo',
    'Goli, Bondoukou, Gontougo',
    'Bambarasso, Bondoukou, Gontougo',

    // RÉGION GRANDS-PONTS
    'Dabou, Dabou, Grands-Ponts',
    'Lopou, Dabou, Grands-Ponts',
    'Toupah, Dabou, Grands-Ponts',
    'Grand-Lahou, Grand-Lahou, Grands-Ponts',
    'Toukouzou, Grand-Lahou, Grands-Ponts',
    'Jacqueville, Jacqueville, Grands-Ponts',
    // Villages proches de Dabou
    'Mopoyem, Dabou, Grands-Ponts',
    'N\'Guessankro, Dabou, Grands-Ponts',
    'Débrimou, Dabou, Grands-Ponts',
    'Cosrou, Dabou, Grands-Ponts',
    'Tiapoum, Dabou, Grands-Ponts',

    // RÉGION GUÉMON
    'Bangolo, Bangolo, Guémon',
    'Fengolo, Bangolo, Guémon',
    'Kahin-Zarabaon, Bangolo, Guémon',
    'Duékoué, Duékoué, Guémon',
    'Facobly, Facobly, Guémon',
    'Guézon, Guézon, Guémon',
    'Kouibly, Kouibly, Guémon',
    // Villages proches de Duékoué
    'Guéhiébly, Duékoué, Guémon',
    'Semien, Duékoué, Guémon',
    'Bagohouo, Duékoué, Guémon',
    'Gbapleu, Duékoué, Guémon',
    'Guinglo-Tahouaké, Duékoué, Guémon',

    // RÉGION HAMBOL
    'Dabakala, Dabakala, Hambol',
    'Foumbolo, Dabakala, Hambol',
    'Katiola, Katiola, Hambol',
    'Fronan, Katiola, Hambol',
    'Niakaramandougou, Niakaramandougou, Hambol',
    'Tortiya, Tortiya, Hambol',
    // Villages proches de Katiola
    'Timbé, Katiola, Hambol',
    'Tafiré, Katiola, Hambol',
    'Nananfouè, Katiola, Hambol',
    'Tortiya-Carrefour, Katiola, Hambol',
    'Niémé, Katiola, Hambol',

    // RÉGION HAUT-SASSANDRA
    'Daloa, Daloa, Haut-Sassandra',
    'Bédiala, Daloa, Haut-Sassandra',
    'Gadouan, Daloa, Haut-Sassandra',
    'Gboguhé, Daloa, Haut-Sassandra',
    'Zaïbo, Daloa, Haut-Sassandra',
    'Issia, Issia, Haut-Sassandra',
    'Nahio, Issia, Haut-Sassandra',
    'Saïoua, Saïoua, Haut-Sassandra',
    'Vavoua, Vavoua, Haut-Sassandra',
    'Dania, Vavoua, Haut-Sassandra',
    'Zéo, Vavoua, Haut-Sassandra',
    // Villages proches de Daloa
    'Zaibo-Carrefour, Daloa, Haut-Sassandra',
    'Gboguhé-Village, Daloa, Haut-Sassandra',
    'Gonaté, Daloa, Haut-Sassandra',
    'Sangouiné, Daloa, Haut-Sassandra',
    'Doualla, Daloa, Haut-Sassandra',

    // RÉGION IFFOU
    'Daoukro, Daoukro, Iffou',
    'M\'Bahiakro, M\'Bahiakro, Iffou',
    'Prikro, Prikro, Iffou',
    // Villages proches de Daoukro
    'Ettrokro, Daoukro, Iffou',
    'Nahounou, Daoukro, Iffou',
    'Kouadio-Yaokro, Daoukro, Iffou',
    'N\'Dénouankro, Daoukro, Iffou',
    'Angolo, Daoukro, Iffou',

    // RÉGION INDÉNIÉ-DJUABLIN
    'Abengourou, Abengourou, Indénié-Djuablin',
    'Aniassué, Abengourou, Indénié-Djuablin',
    'Yakassé-Attobrou, Abengourou, Indénié-Djuablin',
    'Zaranou, Abengourou, Indénié-Djuablin',
    'Agnibilékrou, Agnibilékrou, Indénié-Djuablin',
    'Damé, Agnibilékrou, Indénié-Djuablin',
    'Ebilassokro, Agnibilékrou, Indénié-Djuablin',
    'Tanguélan, Tanguélan, Indénié-Djuablin',
    // Villages proches d'Abengourou
    'Kouassi-Niaguini, Abengourou, Indénié-Djuablin',
    'Amangare, Abengourou, Indénié-Djuablin',
    'Sankadiokro, Abengourou, Indénié-Djuablin',
    'N\'Gattadolikro, Abengourou, Indénié-Djuablin',
    'Niablé, Abengourou, Indénié-Djuablin',

    // RÉGION KABADOUGOU
    'Gbéléban, Gbéléban, Kabadougou',
    'Mankono, Mankono, Kabadougou',
    'Tiéningboué, Mankono, Kabadougou',
    'Odienné, Odienné, Kabadougou',
    'Bako, Odienné, Kabadougou',
    'Dioulatièdougou, Odienné, Kabadougou',
    'Kimbirila-Nord, Odienné, Kabadougou',
    'Madinani, Odienné, Kabadougou',
    'Minignan, Odienné, Kabadougou',
    'Samatiguila, Odienné, Kabadougou',
    'Séguélon, Odienné, Kabadougou',
    // Villages proches d'Odienné
    'Tiémé, Odienné, Kabadougou',
    'Gbéléban-Village, Odienné, Kabadougou',
    'Nafana, Odienné, Kabadougou',
    'Kimbirila-Sud, Odienné, Kabadougou',
    'Dioulatièdougou-Carrefour, Odienné, Kabadougou',

    // RÉGION LA MÊ
    'Adzopé, Adzopé, La Mê',
    'Akoupé, Akoupé, La Mê',
    'Yakassé-Mé, Yakassé-Mé, La Mê',
    // Villages proches d'Adzopé
    'Annépé, Adzopé, La Mê',
    'Bécédi-Brignan, Adzopé, La Mê',
    'Afféry, Adzopé, La Mê',
    'Akakro, Adzopé, La Mê',
    'Danguira, Adzopé, La Mê',

    // RÉGION LÔH-DJIBOUA
    'Divo, Divo, Lôh-Djiboua',
    'Godié, Divo, Lôh-Djiboua',
    'Hiré, Divo, Lôh-Djiboua',
    'Zikisso, Divo, Lôh-Djiboua',
    'Lakota, Lakota, Lôh-Djiboua',
    'Guitry, Lakota, Lôh-Djiboua',
    // Villages proches de Divo
    'Hiré-Watta, Divo, Lôh-Djiboua',
    'Ogoudou, Divo, Lôh-Djiboua',
    'Kragui, Divo, Lôh-Djiboua',
    'Niambézaria, Divo, Lôh-Djiboua',
    'Oghlwapo, Divo, Lôh-Djiboua',

    // RÉGION MARAHOUÉ
    'Bouaflé, Bouaflé, Marahoué',
    'Bonon, Bouaflé, Marahoué',
    'Gohitafla, Bouaflé, Marahoué',
    'Zuénoula, Zuénoula, Marahoué',
    'Bédiala, Zuénoula, Marahoué',
    'Kanzra, Zuénoula, Marahoué',
    // Villages proches de Bouaflé
    'Kononfla, Bouaflé, Marahoué',
    'Bozi, Bouaflé, Marahoué',
    'Diédri, Bouaflé, Marahoué',
    'Gohitafla-Carrefour, Bouaflé, Marahoué',
    'Bazré, Bouaflé, Marahoué',

    // RÉGION MORONOU
    'Arrah, Arrah, Moronou',
    'Bongouanou, Bongouanou, Moronou',
    'M\'Batto, M\'Batto, Moronou',
    'Tiémélékro, Tiémélékro, Moronou',
    // Villages proches de Bongouanou
    'Andé, Bongouanou, Moronou',
    'Ettien, Bongouanou, Moronou',
    'Assuefry, Bongouanou, Moronou',
    'Tié-N\'Diékro, Bongouanou, Moronou',
    'Akpassanou, Bongouanou, Moronou',

    // RÉGION MOYEN-CAVALLY
    'Guéyo, Guéyo, Moyen-Cavally',
    'Guitry, Guitry, Moyen-Cavally',
    'Lakota, Lakota, Moyen-Cavally',
    // Villages proches de Guitry
    'Guitry-Village, Guitry, Moyen-Cavally',
    'Guéyo-Carrefour, Guéyo, Moyen-Cavally',

    // RÉGION N'ZI
    'Bocanda, Bocanda, N\'zi',
    'Dimbokro, Dimbokro, N\'zi',
    'Nofou, Dimbokro, N\'zi',
    'Kouassi-Kouassikro, Kouassi-Kouassikro, N\'zi',
    // Villages proches de Dimbokro
    'Djangokro, Dimbokro, N\'zi',
    'Kouakou-Yaokro, Dimbokro, N\'zi',
    'Niamangué, Dimbokro, N\'zi',
    'Offa, Dimbokro, N\'zi',
    'Diangokro, Dimbokro, N\'zi',

    // RÉGION NAWA
    'Buyo, Buyo, Nawa',
    'Guéyo, Guéyo, Nawa',
    'Grand-Zattry, Nawa, Nawa',
    'Liliyo, Nawa, Nawa',
    // Villages proches de Buyo
    'Gnamagui, Buyo, Nawa',
    'Médon, Buyo, Nawa',
    'Guéyo-Village, Buyo, Nawa',
    'Niambly, Buyo, Nawa',
    'Okrouyo, Buyo, Nawa',

    // RÉGION PORO
    'Dikodougou, Dikodougou, Poro',
    'Korhogo, Korhogo, Poro',
    'Karakoro, Korhogo, Poro',
    'Komborodougou, Korhogo, Poro',
    'Lataha, Korhogo, Poro',
    'Napiéolédougou, Korhogo, Poro',
    'Niofoin, Korhogo, Poro',
    'Sirasso, Korhogo, Poro',
    'M\'Bengué, M\'Bengué, Poro',
    'Sinématiali, Sinématiali, Poro',
    // Villages proches de Korhogo
    'Waraniéné, Korhogo, Poro',
    'Katogo, Korhogo, Poro',
    'Koko, Korhogo, Poro',
    'Napié, Korhogo, Poro',
    'Tioroniaradougou, Korhogo, Poro',

    // RÉGION SAN-PÉDRO
    'San-Pédro, San-Pédro, San-Pédro',
    'Doba, San-Pédro, San-Pédro',
    'Grand-Béréby, San-Pédro, San-Pédro',
    'Tabou, Tabou, San-Pédro',
    'Djiroutou, Tabou, San-Pédro',
    'Grabo, Tabou, San-Pédro',
    'Olodio, Tabou, San-Pédro',
    // Villages proches de San-Pédro
    'Gabiadji, San-Pédro, San-Pédro',
    'Grand-Drewin, San-Pédro, San-Pédro',
    'Nouzonville, San-Pédro, San-Pédro',
    'Olodio-Village, San-Pédro, San-Pédro',
    'Mana, San-Pédro, San-Pédro',

    // RÉGION SUD-COMOÉ
    'Aboisso, Aboisso, Sud-Comoé',
    'Adiaké, Adiaké, Sud-Comoé',
    'Etuéboué, Adiaké, Sud-Comoé',
    'Grand-Bassam, Grand-Bassam, Sud-Comoé',
    'Bonoua, Grand-Bassam, Sud-Comoé',
    'Tiapoum, Tiapoum, Sud-Comoé',
    // Villages proches d'Aboisso
    'Yaou, Aboisso, Sud-Comoé',
    'Kouakro, Aboisso, Sud-Comoé',
    'Maféré, Aboisso, Sud-Comoé',
    'Ayamé, Aboisso, Sud-Comoé',
    'Bianouan, Aboisso, Sud-Comoé',

    // RÉGION TCHOLOGO
    'Ferkessédougou, Ferkessédougou, Tchologo',
    'Kong, Ferkessédougou, Tchologo',
    'Ouangolodougou, Ouangolodougou, Tchologo',
    'Bouna-Kulango, Ouangolodougou, Tchologo',
    // Villages proches de Ferkessédougou
    'Téhini, Ferkessédougou, Tchologo',
    'Kafolo, Ferkessédougou, Tchologo',
    'Niellé, Ferkessédougou, Tchologo',
    'Tiogo, Ferkessédougou, Tchologo',
    'Togoniéré, Ferkessédougou, Tchologo',

    // RÉGION TONKPI
    'Biankouma, Biankouma, Tonkpi',
    'Gbonné, Biankouma, Tonkpi',
    'Kpata, Biankouma, Tonkpi',
    'Danané, Danané, Tonkpi',
    'Bin-Houyé, Danané, Tonkpi',
    'Kouan-Houle, Danané, Tonkpi',
    'Sipilou, Danané, Tonkpi',
    'Man, Man, Tonkpi',
    'Fagnampleu, Man, Tonkpi',
    'Logoualé, Man, Tonkpi',
    'Podiagouiné, Man, Tonkpi',
    'Sandougou-Soba, Man, Tonkpi',
    'Sangouiné, Man, Tonkpi',
    'Yapleu, Man, Tonkpi',
    'Yorodougou, Man, Tonkpi',
    'Ziogouiné, Man, Tonkpi',
    // Villages proches de Man
    'Gbangbégouiné, Man, Tonkpi',
    'Gbèpleu, Man, Tonkpi',
    'Zonneu, Man, Tonkpi',
    'Doualayoupleu, Man, Tonkpi',
    'Dompleu, Man, Tonkpi',

    // RÉGION WORODOUGOU
    'Kani, Kani, Worodougou',
    'Séguéla, Séguéla, Worodougou',
    'Bobi-Diarabana, Séguéla, Worodougou',
    'Djibrosso, Séguéla, Worodougou',
    'Massala, Séguéla, Worodougou',
    'Sifié, Séguéla, Worodougou',
    'Worofla, Séguéla, Worodougou',
    // Villages proches de Séguéla
    'Kamalo, Séguéla, Worodougou',
    'Koumbala, Séguéla, Worodougou',
    'Maninian, Séguéla, Worodougou',
    'Dualla, Séguéla, Worodougou',
    'Tieningboué-Carrefour, Séguéla, Worodougou',
  ];

  /// Normalise une chaîne en supprimant les accents et en mettant en minuscules
  static String _normaliser(String texte) {
    // Map des caractères accentués vers leurs équivalents non accentués
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
      'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a',
      'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
      'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
      'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o',
      'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
      'Ç': 'c', 'Ñ': 'n',
    };

    String resultat = texte.toLowerCase();
    accents.forEach((accent, remplacement) {
      resultat = resultat.replaceAll(accent, remplacement);
    });

    return resultat;
  }

  /// Recherche dans la liste des zones (insensible aux accents et à la casse)
  static List<String> rechercher(String query) {
    if (query.isEmpty) return zones;

    final queryNormalisee = _normaliser(query);
    return zones.where((zone) {
      final zoneNormalisee = _normaliser(zone);
      return zoneNormalisee.contains(queryNormalisee);
    }).toList();
  }

  /// Obtenir les zones par région
  static List<String> parRegion(String region) {
    return zones.where((zone) {
      return zone.endsWith(', $region');
    }).toList();
  }

  /// Obtenir toutes les régions uniques
  static List<String> getRegions() {
    final regions = zones.map((zone) {
      final parts = zone.split(', ');
      return parts.length >= 3 ? parts[2] : '';
    }).where((r) => r.isNotEmpty).toSet().toList();

    regions.sort();
    return regions;
  }
}
