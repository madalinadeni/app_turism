import 'package:cloud_functions/cloud_functions.dart';

class AiService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  Future<Map<String, dynamic>> cautareInteligenta(String text) async {
    final cautare = text.trim();

    if (cautare.length < 3) {
      throw Exception('Introdu o căutare de minimum 3 caractere.');
    }

    try {
      final callable = _functions.httpsCallable('cautareInteligenta');

      final rezultat = await callable.call({'text': cautare});

      if (rezultat.data is! Map) {
        throw Exception('Răspunsul primit de la AI nu este valid.');
      }

      return Map<String, dynamic>.from(rezultat.data as Map);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('Trebuie să fii autentificat pentru a folosi AI.');

        case 'invalid-argument':
          throw Exception(e.message ?? 'Căutarea introdusă nu este validă.');

        case 'resource-exhausted':
          throw Exception(
            'Serviciul AI este momentan ocupat. Încearcă din nou.',
          );

        default:
          throw Exception(
            e.message ?? 'Căutarea inteligentă nu a putut fi procesată.',
          );
      }
    } catch (e) {
      throw Exception('A apărut o eroare la comunicarea cu AI: $e');
    }
  }

  Future<Map<String, dynamic>> genereazaItinerariu({
    required String zona,
    required int zile,
    required double buget,
    required String preferinte,
    required bool cuCopii,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'genereazaItinerariu',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 150)),
      );

      final rezultat = await callable.call({
        'zona': zona.trim(),
        'zile': zile,
        'buget': buget,
        'preferinte': preferinte.trim(),
        'cuCopii': cuCopii,
      });

      final data = rezultat.data;

      if (data is! Map) {
        throw Exception('Răspunsul primit pentru itinerar nu este valid.');
      }

      return Map<String, dynamic>.from(data);
    } on FirebaseFunctionsException catch (error) {
      final mesaj = error.message?.trim();

      if (mesaj != null && mesaj.isNotEmpty) {
        throw Exception(mesaj);
      }

      switch (error.code) {
        case 'unauthenticated':
          throw Exception(
            'Trebuie să fii autentificat pentru a genera un itinerar.',
          );

        case 'invalid-argument':
          throw Exception('Datele introduse pentru itinerar nu sunt valide.');

        case 'not-found':
          throw Exception(
            'Nu există locații disponibile pentru zona introdusă.',
          );

        case 'deadline-exceeded':
          throw Exception(
            'Generarea itinerarului a durat prea mult. Încearcă din nou.',
          );

        default:
          throw Exception('Itinerarul nu a putut fi generat.');
      }
    } catch (error) {
      final mesaj = error.toString().replaceFirst('Exception: ', '');

      throw Exception(mesaj);
    }
  }
}
