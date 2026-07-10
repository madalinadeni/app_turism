const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

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