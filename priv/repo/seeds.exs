# Script d'initialisation de la base CouchDB pour le chatbot.
# Lance la création des bases et l'import du dataset si elles sont vides.
#
# Usage:
#     mix run priv/repo/seeds.exs

require Logger

Logger.info("Initialisation de CouchDB...")

# Assure que les vues Memory sont créées
Chatgpt.Memory.ensure_views!()
Logger.info("Vues CouchDB Memory créées.")

# Charge le dataset depuis priv/dataset.json si la base est vide
docs = Chatgpt.Dataset.seed_if_empty!()
Logger.info("Dataset : #{length(docs)} entrées disponibles.")
