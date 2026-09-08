# Document de cerințe ale produsului (PRD)

# TourMate – Aplicație mobilă pentru promovarea obiectivelor turistice din România

**Versiune:** 1.0
**Ultima actualizare:** 
**Stadiu:** Proiect de licență

## 1. Rezumat executiv

### 1.1 Numele produsului

**TourMate** – aplicație mobilă destinată descoperirii obiectivelor turistice din România și organizării călătoriilor.

### 1.2 Scopul produsului

TourMate urmărește să ofere utilizatorilor un spațiu în care pot descoperi obiective turistice, consulta informații despre acestea și organiza vizite. Aplicația reunește funcționalități de explorare, planificare, interacțiune cu alți utilizatori și asistență bazată pe inteligență artificială.

### 1.3 Utilizatori vizați

**Utilizatorii obișnuiți** pot explora locații, salva favorite, publica recenzii, crea itinerarii și propune obiective turistice noi.

**Administratorii** au responsabilitatea de a verifica propunerile de locații și de a gestiona conținutul turistic disponibil în aplicație.

### 1.4 Obiective principale

* Facilitarea descoperirii obiectivelor turistice din România.
* Oferirea unor informații utile pentru planificarea vizitelor.
* Permiterea organizării itinerariilor personale.
* Încurajarea contribuțiilor utilizatorilor prin recenzii și propuneri de locații.
* Integrarea unor funcționalități AI pentru căutare, planificare și asistență turistică.
* Menținerea unui conținut verificat prin mecanisme de administrare.


## 2. Prezentarea produsului

### 2.1 Descriere generală

TourMate este o aplicație mobilă dezvoltată cu Flutter și Dart, care utilizează Firebase pentru autentificare, stocarea datelor și alte servicii necesare funcționării. Aplicația permite consultarea obiectivelor turistice, gestionarea favoritelor și recenziilor, crearea planificărilor de vacanță și utilizarea unor servicii externe pentru hartă și funcționalități AI.

### 2.2 Funcționalități principale

Aplicația include explorarea și filtrarea locațiilor, afișarea detaliilor turistice, favorite, recenzii, planificări manuale și generate cu AI, propuneri de locații, verificarea administrativă a acestora, hartă, profil, gamificare, notificări, statistici, recomandări și articole turistice.

### 2.3 Limitările produsului

TourMate nu este o platformă de rezervări și nu procesează plăți pentru cazare sau transport. Informațiile despre obiectivele turistice depind de datele disponibile în aplicație, iar sugestiile generate de AI trebuie tratate ca recomandări, nu ca informații garantate.


## 3. Tehnologii utilizate

| Tehnologie               | Rol                                                          |
| ------------------------ | ------------------------------------------------------------ |
| Flutter                  | Dezvoltarea interfeței mobile                                |
| Dart                     | Limbajul de programare                                       |
| Firebase Authentication  | Autentificarea utilizatorilor                                |
| Cloud Firestore          | Stocarea datelor aplicației                                  |
| Firebase Storage         | Stocarea imaginilor                                          |
| Cloud Functions          | Executarea logicii backend necesare anumitor funcționalități |
| Firebase Cloud Messaging | Notificări push                                              |
| Google Maps              | Afișarea locațiilor pe hartă                                 |
| OpenAI API               | Funcționalități de inteligență artificială                   |
| Git și GitHub            | Controlul versiunilor și gestionarea codului sursă           |



## 4. Arhitectura sistemului

### 4.1 Arhitectură generală

Aplicația este organizată în jurul clientului mobil Flutter, care comunică cu serviciile Firebase și cu serviciile externe integrate.

```text
Utilizator
    |
    v
Aplicația TourMate (Flutter)
    |
    +---- Firebase Authentication
    |
    +---- Cloud Firestore
    |
    +---- Firebase Storage
    |
    +---- Cloud Functions
    |         |
    |         +---- Servicii AI
    |
    +---- Google Maps
    |
    +---- Firebase Cloud Messaging
```

### 4.2 Fluxuri principale de date

**Explorarea locațiilor:** aplicația citește datele turistice din Firestore și le afișează utilizatorului.

**Adăugarea unei recenzii:** utilizatorul trimite recenzia, aceasta este salvată în Firestore, iar informațiile afișate despre locație sunt actualizate.

**Propunerea unei locații:** utilizatorul completează formularul, propunerea este salvată pentru verificare, iar administratorul decide aprobarea sau respingerea acesteia.

**Generarea unui itinerariu AI:** aplicația transmite cererea către serviciul backend, primește rezultatul generat și permite salvarea planificării.


## 5. Proiectarea bazei de date

### 5.1 Modelul de date

TourMate utilizează Cloud Firestore, o bază de date NoSQL organizată în colecții și documente.

### 5.2 Colecții principale

| Colecție            | Scop                                                      |
| ------------------- | --------------------------------------------------------- |
| `utilizatori`       | Datele utilizatorilor și informațiile asociate conturilor |
| `locatii`           | Obiectivele turistice publicate                           |
| `propuneri_locatii` | Propunerile trimise pentru verificare                     |
| `itinerarii`        | Planificările de vacanță                                  |
| `articole`          | Articolele turistice                                      |
| `experiente`        | Datele asociate experiențelor turistice                   |
| `trasee`            | Informații despre trasee                                  |

### 5.3 Subcolecții

În funcție de funcționalitate, datele pot fi organizate și în subcolecții, precum `preferate`, `notificari`, `fcmTokens` și `recenzii`.

### 5.4 Exemplu de document pentru o locație

```text
locatii/{locatieId}
    nume
    descriere
    categorie
    judet
    oras
    orar
    coordonate
        lat
        lng
    imagini
    facilitati
    rating
    nrRecenzii
    pretMin
    pretMax
    popular
    creatLa
    creatDe


## 6. Funcționalități principale

### 6.1 Autentificare și gestionarea contului

**Cerințe:** utilizatorul trebuie să poată crea un cont, să se autentifice, să își recupereze parola și să își gestioneze informațiile de profil.

**Implementare:** autentificarea este realizată prin Firebase Authentication, iar datele suplimentare ale utilizatorului sunt gestionate prin serviciile aplicației.

### 6.2 Explorarea obiectivelor turistice

**Cerințe:** utilizatorul poate vizualiza locațiile disponibile, căuta după text, filtra după categorie și consulta informațiile detaliate.

**Date afișate:** nume, descriere, imagini, categorie, localizare, program, prețuri, facilități și rating, în funcție de informațiile disponibile.

### 6.3 Favorite și recenzii

Utilizatorul poate salva locații în lista de favorite și poate publica recenzii. Aceste funcționalități permit păstrarea obiectivelor de interes și exprimarea experiențelor personale.

### 6.4 Planificarea călătoriilor

Aplicația permite crearea și salvarea planificărilor de vacanță. Utilizatorul poate organiza manual un itinerariu sau poate utiliza funcționalitatea AI pentru generarea unei propuneri de călătorie.

### 6.5 Propunerea și verificarea locațiilor

Utilizatorul poate trimite o propunere de obiectiv turistic. Administratorul verifică informațiile și poate aproba sau respinge propunerea. În cazul respingerii, poate fi introdus un motiv.

### 6.6 Funcționalități AI

TourMate include căutare inteligentă, generare de itinerarii și chatbot turistic. Aceste funcționalități sunt integrate prin serviciile backend ale aplicației.

### 6.7 Hartă și localizare

Utilizatorul poate vizualiza obiectivele turistice pe hartă și poate utiliza poziția curentă, atunci când acordă permisiunile necesare.

### 6.8 Gamificare

Aplicația include un sistem de puncte, niveluri, titluri și insigne, destinat încurajării utilizării funcționalităților și interacțiunii cu platforma.

### 6.9 Notificări

Utilizatorii pot primi notificări în aplicație și notificări push pentru evenimentele relevante implementate în TourMate.

### 6.10 Statistici și recomandări

Aplicația afișează statistici despre obiectivele turistice și activitatea utilizatorului, precum și recomandări bazate pe datele disponibile. Recomandările euristice sunt distincte de funcționalitățile AI.

### 6.11 Articole turistice

Utilizatorii pot consulta articole turistice, iar administratorii pot gestiona conținutul acestora.


## 7. Roluri și permisiuni

### 7.1 Utilizator obișnuit

Poate utiliza funcționalitățile de explorare, favorite, recenzii, planificare, AI, hartă, profil, notificări și propunere de locații, în limitele permisiunilor stabilite.

### 7.2 Administrator

Are acces la funcționalitățile utilizatorului și la operațiile administrative, precum verificarea propunerilor și gestionarea articolelor turistice.

### 7.3 Controlul accesului

Accesul la date și operații trebuie realizat în funcție de identitatea utilizatorului și de rolul acestuia. Regulile Firebase și verificările din aplicație trebuie să împiedice modificarea neautorizată a datelor.



## 8. Servicii backend și integrări

### 8.1 Cloud Functions

Funcțiile backend sunt utilizate pentru operațiile care necesită logică executată în afara clientului mobil, inclusiv funcționalitățile AI și trimiterea notificărilor push.

### 8.2 Integrarea AI

Funcționalitățile AI sunt gestionate prin serviciile aplicației și prin funcțiile backend corespunzătoare. Cheile necesare accesării serviciilor externe nu trebuie incluse în codul public al repository-ului.

### 8.3 Integrarea Google Maps

Harta utilizează coordonatele obiectivelor turistice pentru afișarea markerelor și serviciile de localizare pentru determinarea poziției utilizatorului.

### 8.4 Documentația API

Pentru fiecare funcție backend relevantă se pot documenta numele, scopul, datele de intrare, rezultatul și eventualele erori. Detaliile exacte trebuie preluate din implementarea finală.


## 9. Securitate și protecția datelor

Aplicația utilizează Firebase Authentication pentru identificarea utilizatorilor și reguli de acces pentru protejarea datelor. Operațiile administrative trebuie limitate la conturile autorizate.

Cheile API, parolele și alte informații secrete nu trebuie publicate în repository. Fișierele de configurare necesare dezvoltării trebuie tratate conform rolului lor, iar valorile sensibile trebuie păstrate în afara codului public.


## 10. Experiența utilizatorului

Interfața urmărește să ofere acces ușor la funcționalitățile principale prin navigare clară, formulare și mesaje de feedback. Utilizatorul trebuie să poată identifica rapid locațiile de interes, să consulte detaliile și să își gestioneze planificările.

Pentru operațiile care modifică date, aplicația trebuie să ofere confirmări sau mesaje de eroare corespunzătoare.


## 11. Dezvoltare și instalare

### 11.1 Cerințe preliminare

* Flutter SDK și Dart.
* Android Studio sau un alt mediu compatibil.
* Un emulator Android sau un dispozitiv fizic.
* Acces la proiectul Firebase configurat pentru aplicație.
* Configurările necesare serviciilor externe utilizate.

### 11.2 Pași generali de rulare

```bash
flutter pub get
flutter run
```


### 11.3 Controlul versiunilor

Codul sursă este gestionat prin Git și poate fi publicat într-un repository GitHub. Repository-ul trebuie să conțină fișierele necesare pentru înțelegerea, compilarea și rularea proiectului, fără secrete sau fișiere generate inutile.


## 12. Testare și validare

Funcționalitățile aplicației pot fi validate prin scenarii care urmăresc autentificarea, explorarea locațiilor, salvarea favoritelor, publicarea recenziilor, crearea itinerariilor, trimiterea și verificarea propunerilor, utilizarea AI și afișarea hărții.

Pentru fiecare scenariu se pot documenta acțiunea efectuată, rezultatul așteptat și rezultatul obținut. Această secțiune trebuie completată cu testele efectiv realizate asupra versiunii finale.


## 13. Direcții viitoare de dezvoltare

Posibile dezvoltări ulterioare includ extinderea bazei de obiective turistice, îmbunătățirea recomandărilor, planificarea itinerariilor în funcție de distanțe și programul de vizitare, funcționalități offline, suport pentru mai multe limbi și extinderea sistemului de gamificare.

Aceste funcționalități reprezintă direcții viitoare și nu sunt prezentate ca fiind deja implementate.


## 14. Concluzie

TourMate reunește într-o aplicație mobilă funcționalități de informare turistică, planificare și interacțiune cu utilizatorii. Documentul prezintă cerințele și structura generală a produsului și poate fi actualizat pe măsură ce implementarea evoluează. Pentru detaliile tehnice exacte, sursa de referință rămâne codul aplicației și documentația proiectului.
