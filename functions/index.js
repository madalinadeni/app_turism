const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

const openAiApiKey = defineSecret("OPENAI_API_KEY");

let openAIClient;

async function getOpenAIClient() {
  if (!openAIClient) {
    const {default: OpenAI} = await import("openai");

    openAIClient = new OpenAI({
      apiKey: openAiApiKey.value(),
    });
  }

  return openAIClient;
}

exports.cautareInteligenta = onCall(
  {
    region: "europe-west1",
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
    maxInstances: 5,
  },
  async (request) => {
    logger.info("cautareInteligenta a fost apelată", {
        autentificat: Boolean(request.auth),
        text: request.data?.text,
    });
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Trebuie să fii autentificat pentru a folosi căutarea AI.",
      );
    }

    const text = request.data?.text;

    if (typeof text !== "string" || text.trim().length < 3) {
      throw new HttpsError(
        "invalid-argument",
        "Introdu o căutare de minimum 3 caractere.",
      );
    }

    if (text.length > 300) {
      throw new HttpsError(
        "invalid-argument",
        "Căutarea este prea lungă.",
      );
    }

    try {
      const openai = await getOpenAIClient();

      const response = await openai.responses.create({
        model: "gpt-4o-mini",
        store: false,
        instructions: `
Ești un asistent pentru o aplicație turistică din România.

Extrage filtrele relevante din cererea utilizatorului.

Exemple:
- "Vreau un castel aproape de Brașov"
  categorie = "Castel", oras = "Brașov"

- "Muzee în București"
  categorie = "Muzeu", oras = "București"

- "Locuri potrivite pentru copii"
  potrivitCopii = true

- "Atracții gratuite în aer liber în Cluj"
  oras = "Cluj", gratuit = true, inAerLiber = true

Folosește șir gol când informația nu este specificată.
Nu inventa orașe, județe sau categorii.
        `,
        input: text.trim(),
        text: {
          format: {
            type: "json_schema",
            name: "filtre_cautare_turistica",
            strict: true,
            schema: {
              type: "object",
              properties: {
                categorie: {
                  type: "string",
                },
                oras: {
                  type: "string",
                },
                judet: {
                  type: "string",
                },
                facilitati: {
                  type: "array",
                  items: {
                    type: "string",
                  },
                },
                cuvinteCheie: {
                  type: "array",
                  items: {
                    type: "string",
                  },
                },
                potrivitCopii: {
                  type: "boolean",
                },
                gratuit: {
                  type: "boolean",
                },
                inAerLiber: {
                  type: "boolean",
                },
              },
              required: [
                "categorie",
                "oras",
                "judet",
                "facilitati",
                "cuvinteCheie",
                "potrivitCopii",
                "gratuit",
                "inAerLiber",
              ],
              additionalProperties: false,
            },
          },
        },
      });

      if (!response.output_text) {
        throw new Error("Răspunsul AI este gol.");
      }

      return JSON.parse(response.output_text);
    } catch (error) {
      const detaliiEroare = {
        message: error?.message ?? String(error),
        status: error?.status ?? null,
        code: error?.code ?? error?.error?.code ?? null,
        type: error?.type ?? error?.error?.type ?? null,
        requestId: error?.request_id ?? null,
        apiError: error?.error ?? null,
      };

      console.error(
        "OPENAI_ERROR:",
        JSON.stringify(detaliiEroare),
      );

      logger.error(
        "Eroare la căutarea inteligentă",
        error,
      );

      throw new HttpsError(
              "internal",
              `Eroare AI (${detaliiEroare.status ?? "fără status"} / ${
                detaliiEroare.code ?? "fără cod"
              }).`,
      );
    }
 },
 );

 exports.genereazaItinerariu = onCall(
    {
      region: "europe-west1",
      secrets: [openAiApiKey],
      timeoutSeconds: 120,
      memory: "512MiB",
      maxInstances: 5,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "Trebuie să fii autentificat pentru a genera un itinerar.",
        );
      }

      const zona = request.data?.zona?.toString().trim() ?? "";
      const preferinte =
        request.data?.preferinte?.toString().trim() ?? "";

      const zile = Number(request.data?.zile);
      const buget = Number(request.data?.buget);
      const cuCopii = request.data?.cuCopii === true;

      if (zona.length < 2) {
        throw new HttpsError(
          "invalid-argument",
          "Introdu un oraș sau un județ.",
        );
      }

      if (!Number.isInteger(zile) || zile < 1 || zile > 14 ) {
        throw new HttpsError(
          "invalid-argument",
          "Numărul de zile trebuie să fie între 1 și 14.",
        );
      }

      if (!Number.isFinite(buget) || buget < 0 || buget > 100000) {
        throw new HttpsError(
          "invalid-argument",
          "Bugetul introdus nu este valid.",
        );
      }

      try {
        const locatiiSnapshot = await db
          .collection("locatii")
          .get();

        if (locatiiSnapshot.empty) {
          throw new HttpsError(
            "not-found",
            "Nu există locații disponibile pentru itinerar.",
          );
        }

        const normalizeaza = (valoare) => {
          return valoare
            .toString()
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .trim();
        };

        const zonaNormalizata = normalizeaza(zona);

        const toateLocatiile = locatiiSnapshot.docs.map((document) => {
          const data = document.data();

          const coordonate = data.coordonate ?? {};

          return {
            id: document.id,
            nume: data.nume?.toString() ?? "",
            categorie: data.categorie?.toString() ?? "",
            oras: data.oras?.toString() ?? "",
            judet: data.judet?.toString() ?? "",
            descriere: (() => {
              const descriere = data.descriere?.toString() ?? "";

              return descriere.length > 300
                ? descriere.substring(0, 300)
                : descriere;
            })(),
            orar: data.orar?.toString() ?? "",
            pretMin: Number(data.pretMin ?? 0),
            pretMax: Number(data.pretMax ?? 0),
            rating: Number(data.rating ?? 0),
            nrRecenzii: Number(data.nrRecenzii ?? 0),
            facilitati: Array.isArray(data.facilitati)
              ? data.facilitati.slice(0, 10)
              : [],
           latitudine: Number(
             coordonate.latitude ??
             coordonate.lat ??
             data.latitudine ??
             0
           ),

           longitudine: Number(
             coordonate.longitude ??
             coordonate.lng ??
             data.longitudine ??
             0
           ),
          };
        });

        let locatiiDisponibile = toateLocatiile.filter((locatie) => {
          const textZona = normalizeaza(
            `${locatie.oras} ${locatie.judet} ${locatie.nume}`,
          );

          return textZona.includes(zonaNormalizata);
        });

        /*
          Daca nu gasim o potrivire exacta pentru zona aleasa,
          trimitem toate locatiile, iar AI-ul selecteaza cele mai apropiate
          variante disponibile.
         */

        if (locatiiDisponibile.length === 0) {
          throw new HttpsError(
            "not-found",
            `Nu există locații disponibile pentru zona „${zona}”.`,
          );
        }

        /*
         Limitam numarul de locatii pentru ca promptul sa nu devina prea mare,
         acordand prioritate celor cu ratinguri si recenzii mai bune.
         */

        locatiiDisponibile.sort((a, b) => {
          if (b.rating !== a.rating) {
            return b.rating - a.rating;
          }
          return b.nrRecenzii - a.nrRecenzii;
        });

        locatiiDisponibile = locatiiDisponibile.slice(0, 60);

        const openai = await getOpenAIClient();

        const response = await openai.responses.create({
          model: "gpt-4o-mini",
          store: false,

          instructions: `
  Ești un planificator turistic pentru România.

  Generează un itinerar realist folosind EXCLUSIV locațiile primite
  în lista "locatiiDisponibile".

  Reguli obligatorii:
  - Nu inventa locații.
  - Folosește exact ID-ul locației primit.
  - Nu repeta aceeași locație.
  - Creează exact numărul de zile cerut.
  - Include între 1 și 4 activități pe zi.
  - Ordonează activitățile în mod realist.
  - Ține cont de oraș, județ, preferințe, buget și copii.
  - Costul estimat trebuie să fie realist.
  - Dacă bugetul este 0, favorizează locațiile gratuite.
  - Pentru copii, favorizează locații familiale și activități ușoare.
  - Nu recomanda activități în afara locațiilor disponibile.
  - Explicațiile trebuie să fie în limba română.
          `,

          input: JSON.stringify({
            cerere: {
              zona,
              zile,
              buget,
              preferinte,
              cuCopii,
            },
            locatiiDisponibile,
          }),

          text: {
            format: {
              type: "json_schema",
              name: "itinerar_turistic",
              strict: true,
              schema: {
                type: "object",

                properties: {
                  titlu: {
                    type: "string",
                  },

                  rezumat: {
                    type: "string",
                  },

                  zona: {
                    type: "string",
                  },

                  numarZile: {
                    type: "integer",
                  },

                  bugetTotalEstimat: {
                    type: "number",
                  },

                  sfaturi: {
                    type: "array",
                    items: {
                      type: "string",
                    },
                  },

                  zile: {
                    type: "array",
                    items: {
                      type: "object",

                      properties: {
                        zi: {
                          type: "integer",
                        },

                        titlu: {
                          type: "string",
                        },

                        activitati: {
                          type: "array",
                          items: {
                            type: "object",

                            properties: {
                              ora: {
                                type: "string",
                              },

                              locatieId: {
                                type: "string",
                              },

                              numeLocatie: {
                                type: "string",
                              },

                              categorie: {
                                type: "string",
                              },

                              motiv: {
                                type: "string",
                              },

                              durataOre: {
                                type: "number",
                              },

                              costEstimat: {
                                type: "number",
                              },
                            },

                            required: [
                              "ora",
                              "locatieId",
                              "numeLocatie",
                              "categorie",
                              "motiv",
                              "durataOre",
                              "costEstimat",
                            ],

                            additionalProperties: false,
                          },
                        },
                      },

                      required: [
                        "zi",
                        "titlu",
                        "activitati",
                      ],

                      additionalProperties: false,
                    },
                  },
                },

                required: [
                  "titlu",
                  "rezumat",
                  "zona",
                  "numarZile",
                  "bugetTotalEstimat",
                  "sfaturi",
                  "zile",
                ],

                additionalProperties: false,
              },
            },
          },
        });

        if (!response.output_text) {
          throw new Error(
            "Răspunsul pentru itinerar este gol.",
          );
        }

        const itinerar = JSON.parse(response.output_text);

        /*
            Verificam ca ID-urile returnate de AI sa existe in lista trimisa.
        */

        const idsValide = new Set(
          locatiiDisponibile.map((locatie) => locatie.id),
        );

        for (const zi of itinerar.zile) {
          zi.activitati = zi.activitati.filter((activitate) => {
            return idsValide.has(activitate.locatieId);
          });
        }

        return itinerar;
      } catch (error) {
        if (error instanceof HttpsError) {
          throw error;
        }

        const detaliiEroare = {
          message: error?.message ?? String(error),
          status: error?.status ?? null,
          code:
            error?.code ??
            error?.error?.code ??
            null,
          type:
            error?.type ??
            error?.error?.type ??
            null,
          requestId: error?.request_id ?? null,
        };

        logger.error(
          "Eroare la generarea itinerarului",
          detaliiEroare,
        );

        throw new HttpsError(
          "internal",
          `Itinerarul nu a putut fi generat (${
            detaliiEroare.status ?? "fără status"
          } / ${
            detaliiEroare.code ?? "fără cod"
          }).`,
        );
      }
    },
  );