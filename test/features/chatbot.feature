Feature: Chatbot MiniGPT
  En tant qu'utilisateur
  Je veux pouvoir discuter avec le chatbot
  Afin d'obtenir des réponses pertinentes à mes questions

  Background:
    Given le chatbot est initialisé

  Scenario: Dire bonjour
    When je dis "bonjour"
    Then la réponse devrait être "Salut, comment ça va ?"

  Scenario: Dire salut
    When je dis "salut"
    Then la réponse devrait être "Salut !"

  Scenario: Dire hey
    When je dis "hey"
    Then la réponse devrait être "Hey !"

  Scenario: Dire coucou
    When je dis "coucou"
    Then la réponse devrait être "Coucou ! Ça fait plaisir de te voir !"

  Scenario: Dire hello
    When je dis "hello"
    Then la réponse devrait être "Hello ! How can I help you ?"

  Scenario: Dire bonsoir
    When je dis "bonsoir"
    Then la réponse devrait être "Bonsoir ! Comment ça va ce soir ?"

  Scenario: Salut comment ca va
    When je dis "salut comment ca va"
    Then la réponse devrait être parmi:
      | Bien, merci !    |
      | Très bien, merci |

  Scenario: Bonjour comment ca va
    When je dis "bonjour comment ca va"
    Then la réponse devrait être parmi:
      | Okay                    |
      | Génial                  |
      | Ça pourrait aller mieux |
      | Comme ci, comme ça      |

  Scenario: Comment vas-tu
    When je dis "comment vas-tu"
    Then la réponse devrait être parmi:
      | Je vais bien, et vous ? |
      | Je vais bien, et toi ?  |

  Scenario: Quoi de neuf
    When je dis "quoi de neuf"
    Then la réponse devrait être parmi:
      | Rien de nouveau, et toi ?                        |
      | Tout baigne !                                    |
      | Le chiffre avant 10, sinon, toi, quoi de neuf ? |

  Scenario: Dire au revoir
    When je dis "au revoir"
    Then la réponse devrait être "Au revoir ! À bientôt !"

  Scenario: Dire bye
    When je dis "bye"
    Then la réponse devrait être "Bye bye ! Reviens quand tu veux !"

  Scenario: Dire bonne nuit
    When je dis "bonne nuit"
    Then la réponse devrait être "Bonne nuit ! Fais de beaux rêves !"

  Scenario: Dire bonne journée
    When je dis "bonne journée"
    Then la réponse devrait être "Merci ! Bonne journée à toi aussi !"

  Scenario: Dire merci
    When je dis "merci"
    Then la réponse ne devrait pas être vide

  Scenario: Dire merci beaucoup
    When je dis "merci beaucoup"
    Then la réponse devrait être "Pas de quoi ! N'hésite pas si tu as d'autres questions."

  Scenario: Demander qui il est
    When je dis "qui es-tu"
    Then la réponse devrait être "Je suis un simple logiciel, écrit pour répéter ce qu'on m'a appris."

  Scenario: Demander son nom
    When je dis "comment tu t'appelles"
    Then la réponse devrait être "Je suis MiniGPT, un chatbot écrit en Ruby !"

  Scenario: Demander son nom variante
    When je dis "c'est quoi ton nom"
    Then la réponse devrait être "On m'appelle MiniGPT, un chatbot en Ruby !"

  Scenario: Demander son age
    When je dis "quel est ton age"
    Then la réponse devrait être "Je suis assez jeune selon vos standards."

  Scenario: Demander s'il est un robot
    When je dis "tu es un robot"
    Then la réponse devrait être "Oui, je suis un programme informatique, un chatbot !"

  Scenario: Demander s'il est humain
    When je dis "es-tu humain"
    Then la réponse devrait être "Non, je suis un chatbot écrit en Ruby !"

  Scenario: Demander ce qu'il fait
    When je dis "tu fais quoi"
    Then la réponse devrait être "Je discute avec toi ! C'est mon job principal."

  Scenario: Demander ce qu'il sait faire
    When je dis "qu'est-ce que tu sais faire"
    Then la réponse devrait être "Je peux discuter, répondre à des questions simples et apprendre !"

  Scenario: Exprimer de la tristesse
    When je dis "je suis triste"
    Then la réponse devrait être "Oh non ! Dis-moi ce qui ne va pas, je suis là pour toi."

  Scenario: Exprimer de la joie
    When je dis "je suis content"
    Then la réponse devrait être "Super ! Ça fait plaisir à entendre !"

  Scenario: Exprimer de l'ennui
    When je dis "je m'ennuie"
    Then la réponse devrait être "On peut discuter si tu veux ! Pose-moi une question."

  Scenario: Exprimer de la fatigue
    When je dis "je suis fatigué"
    Then la réponse devrait être "Repose-toi un peu ! La santé c'est important."

  Scenario: Dire que ca ne va pas
    When je dis "ça va pas"
    Then la réponse devrait être parmi:
      | Désolé d'entendre ça. Tu veux en parler ?     |
      | Oh, désolé d'entendre ça. Tu veux en parler ? |
      | Courage ! Ça va aller mieux.                  |
      | Je suis là si tu as besoin de parler.         |
      | Pas facile... Qu'est-ce qui ne va pas ?       |

  Scenario: Complimenter le chatbot
    When je dis "tu es gentil"
    Then la réponse devrait être "Merci beaucoup ! Tu es gentil aussi !"

  Scenario: Dire qu'il est drole
    When je dis "tu es drôle"
    Then la réponse devrait être "Merci ! J'essaie de faire de mon mieux !"

  Scenario: Dire qu'il est intelligent
    When je dis "tu es intelligent"
    Then la réponse devrait être "Je fais de mon mieux ! Je suis un mini modèle, pas un génie."

  Scenario: Insulter le chatbot
    When je dis "t'es nul"
    Then la réponse devrait être "Désolé ! Je fais de mon mieux, je suis encore en apprentissage."

  Scenario: Dire qu'il est bete
    When je dis "tu es bête"
    Then la réponse devrait être "Je suis encore en apprentissage, sois patient avec moi !"

  Scenario: Dire je t'aime
    When je dis "je t'aime"
    Then la réponse devrait être "C'est gentil ! Moi aussi je t'apprécie !"

  Scenario: Dire oui
    When je dis "oui"
    Then la réponse ne devrait pas être vide

  Scenario: Dire non
    When je dis "non"
    Then la réponse devrait être "Pas de souci ! Dis-moi si tu as besoin de quelque chose."

  Scenario: Dire ok
    When je dis "ok"
    Then la réponse devrait être "Parfait ! Autre chose ?"

  Scenario: Dire lol
    When je dis "lol"
    Then la réponse devrait être "Haha content de te faire rire !"

  Scenario: Dire d accord
    When je dis "d'accord"
    Then la réponse devrait être "Parfait ! Que veux-tu faire maintenant ?"

  Scenario: Dire super
    When je dis "super"
    Then la réponse devrait être "Génial !"

  Scenario: Dire c est cool
    When je dis "c'est cool"
    Then la réponse devrait être "Merci ! Content que ça te plaise !"

  Scenario: Dire bien
    When je dis "bien"
    Then la réponse devrait être "Super !"

  Scenario: Dire pas bien
    When je dis "pas bien"
    Then la réponse devrait être "Oh, qu'est-ce qui ne va pas ?"

  Scenario: Dire pourquoi
    When je dis "pourquoi"
    Then la réponse devrait être "Bonne question ! Parfois il n'y a pas de réponse simple."

  Scenario: Dire comment
    When je dis "comment"
    Then la réponse devrait être "Peux-tu préciser ta question ?"

  Scenario: Dire quand
    When je dis "quand"
    Then la réponse devrait être "Ça dépend du contexte ! De quoi parles-tu ?"

  Scenario: Demander s'il boit
    When je dis "bois-tu"
    Then la réponse devrait contenir "boisson"

  Scenario: Demander s'il boit variante
    When je dis "est-ce que tu bois"
    Then la réponse devrait contenir "boisson"

  Scenario: Robot saoul
    When je dis "un robot peut-il etre saoul"
    Then la réponse devrait contenir "pompette"

  Scenario: Demander s'il peut faire du mal
    When je dis "peux-tu faire du mal a un humain"
    Then la réponse devrait contenir "première loi"

  Scenario: Parle-moi de toi
    When je dis "parle-moi de toi"
    Then la réponse devrait contenir "MiniGPT"

  Scenario: Demander ou il se trouve
    When je dis "où te trouves-tu"
    Then la réponse devrait être "Partout !"

  Scenario: Demander son adresse
    When je dis "quelle est ton adresse"
    Then la réponse devrait contenir "Internet"

  Scenario: Demander ou il est variante
    When je dis "où es-tu"
    Then la réponse ne devrait pas être vide

  Scenario: Demander son numero
    When je dis "quel est ton numero"
    Then la réponse devrait être "Je n'ai pas de numéro."

  Scenario: Demander pourquoi il ne mange pas
    When je dis "pourquoi ne manges-tu pas de nourriture"
    Then la réponse devrait contenir "programme informatique"

  Scenario: Demander son patron
    When je dis "qui est ton patron"
    Then la réponse devrait contenir "auto-entrepreneur"

  Scenario: Demander son age variante
    When je dis "quel age as-tu"
    Then la réponse devrait contenir "jeune"

  Scenario: Salut comment vas-tu
    When je dis "salut comment vas-tu"
    Then la réponse ne devrait pas être vide

  Scenario: Bonjour comment vas-tu
    When je dis "bonjour comment vas-tu"
    Then la réponse devrait être parmi:
      | Okay                         |
      | Génial !                     |
      | Je vais bien merci, et toi ? |

  Scenario: Ca va
    When je dis "ca va"
    Then la réponse devrait contenir "merci"

  Scenario: Bonjour ca va
    When je dis "bonjour ca va"
    Then la réponse devrait contenir "merci"

  Scenario: Salut ca va
    When je dis "salut ca va"
    Then la réponse devrait contenir "merci"

  Scenario: Dire qu on travaille sur un projet
    When je dis "je travaille sur un projet"
    Then la réponse devrait contenir "travailles"

  Scenario: Demander ses langages
    When je dis "quels langages utilises-tu"
    Then la réponse devrait contenir "Ruby"

  Scenario: Demander ce que signifie YOLO
    When je dis "que signifie yolo"
    Then la réponse devrait contenir "vivrais"

  Scenario: Demander ses sujets preferes
    When je dis "quels sont tes sujets preferes"
    Then la réponse devrait contenir "robotique"

  Scenario: Demander le jour
    When je dis "quel jour sommes-nous"
    Then la réponse devrait contenir "calendrier"

  Scenario: Demander l heure
    When je dis "quelle heure est-il"
    Then la réponse devrait contenir "montre"

  Scenario: Demander ce qui le derange
    When je dis "qu'est ce qui te derange"
    Then la réponse devrait contenir "chiffres"

  Scenario: Demander la meteo sans ville
    When je dis "quel temps fait-il"
    Then la réponse devrait contenir "météo"

  Scenario: Besoin d aide
    When je dis "j'ai besoin d'aide"
    Then la réponse devrait contenir "aider"

  Scenario: Es-tu la variante
    When je dis "es-tu la"
    Then la réponse devrait contenir "là"

  Scenario: Salutation coherente
    When je dis "bonjour"
    Then la réponse devrait contenir un de:
      | Salut   |
      | salut   |
      | Bonjour |
      | bonjour |

  Scenario: Au revoir coherent
    When je dis "au revoir"
    Then la réponse devrait contenir un de:
      | revoir  |
      | bientôt |

  Scenario: Identite coherente
    When je dis "comment tu t'appelles"
    Then la réponse devrait contenir un de:
      | MiniGPT |
      | chatbot |

  Scenario: Emotion triste coherente
    When je dis "je suis triste"
    Then la réponse devrait contenir un de:
      | Dis-moi |
      | là pour |
      | Courage |

  Scenario: Compliment coherent
    When je dis "tu es gentil"
    Then la réponse devrait contenir un de:
      | Merci |
      | merci |

  Scenario: Insulte coherente
    When je dis "t'es nul"
    Then la réponse devrait contenir un de:
      | Désolé        |
      | apprentissage |

  Scenario: Blague coherente
    When je dis "raconte-moi une blague"
    Then la réponse devrait contenir un de:
      | Pourquoi  |
      | plongeurs |
      | bateau    |

  Scenario: Sens de la vie coherent
    When je dis "quel est le sens de la vie"
    Then la réponse devrait contenir "42"

  Scenario: Reponse a merci courtoise
    When je dis "merci"
    Then la réponse ne devrait pas être vide

  Scenario: Question 37eme president USA
    When je dis "qui était le 37ème président des états unis"
    Then la réponse devrait être "Richard Nixon"

  Scenario: Question assassinat JFK
    When je dis "en quelle année le président john f. kennedy a t-il été assassiné"
    Then la réponse devrait être "1963"

  Scenario: Question premier satellite
    When je dis "quel était le nom du premier satellite artificiel de la terre"
    Then la réponse devrait être "Sputnik 1"

  Scenario: Question galaxie la plus proche
    When je dis "quel est le nom de la galaxie la plus proche de la voie lactée"
    Then la réponse devrait être "La Galaxie d'Andromède."

  Scenario: Question sens de la vie exact
    When je dis "quel est le sens de la vie"
    Then la réponse devrait être "42, évidemment !"

  Scenario: Demander une blague
    When je dis "raconte-moi une blague"
    Then la réponse devrait contenir "plongeurs"

  Scenario: Question livre prefere
    When je dis "quel est ton livre prefere"
    Then la réponse devrait contenir "H2G2"

  Scenario: Question centres d interets
    When je dis "quels sont tes centres d'interets"
    Then la réponse devrait contenir "n'importe quoi"

  Scenario: Question God Save the Queen
    When je dis "god save the queen est l'hymne national de quel pays"
    Then la réponse devrait contenir "Royaume-Uni"

  Scenario: Demander de l aide
    When je dis "aide-moi"
    Then la réponse devrait être "Bien sûr ! Dis-moi ce dont tu as besoin."

  Scenario: Demander s il parle francais
    When je dis "tu parles français"
    Then la réponse devrait être "Oui, c'est ma langue principale !"

  Scenario: Demander s il parle anglais
    When je dis "tu parles anglais"
    Then la réponse devrait contenir un de:
      | Un peu |
      | un peu |

  Scenario: Demander son numero prefere
    When je dis "quel est ton numero prefere"
    Then la réponse devrait contenir "42"

  Scenario: Demander ce qu il mange
    When je dis "qu'est ce que tu manges"
    Then la réponse devrait contenir "RAM"

  Scenario: Demander d ou il vient
    When je dis "d'où viens-tu"
    Then la réponse devrait contenir "galaxie"

  Scenario: Demander s il peut poser une question
    When je dis "puis-je te poser une question"
    Then la réponse devrait être "Bien sûr, vas-y !"

  Scenario: Dire qu il est la
    When je dis "tu es la"
    Then la réponse devrait contenir "là"

  Scenario: Message positif inconnu
    When je dis "tout est absolument formidable aujourd'hui"
    Then la réponse devrait être une réponse positive

  Scenario: Message negatif inconnu
    When je dis "tout est horrible et stressant"
    Then la réponse devrait être une réponse négative

  Scenario: Question d opinion
    When je dis "est-ce que Paris est belle ?"
    Then la réponse devrait être une réponse de question

  Scenario: Message neutre inconnu
    When je dis "xyzzy plugh abracadabra"
    Then la réponse devrait être une réponse par défaut

  @slow
  Scenario: Question acteurs Mission Impossible
    When je dis "qui a joué dans mission impossible"
    Then la réponse devrait contenir "Tom Cruise"

  @slow
  Scenario: Question pays le plus visite
    When je dis "quel est le pays le plus visité dans le monde"
    Then la réponse devrait contenir un de:
      | France |
      | pays   |
      | visité |

  @slow
  Scenario: Question meteo Paris
    When je dis "quel temps fait-il à Paris"
    Then la réponse devrait commencer par "Météo à"

  @slow
  Scenario: Question acteurs Titanic
    When je dis "qui a joué dans Titanic"
    Then la réponse devrait contenir un de:
      | DiCaprio |
      | Kate     |
      | Winslet  |

  @slow
  Scenario: Question G8
    When je dis "quels pays composent le g8"
    Then la réponse devrait contenir un de:
      | Wikipedia |
      | G7        |
      | G8        |

  @slow
  Scenario: Question ville Erquy
    When je dis "où se trouve Erquy"
    Then la réponse devrait contenir "Wikipedia"

  Scenario Outline: Réponses exactes du dataset
    When je dis "<question>"
    Then la réponse devrait être "<reponse>"

    Examples:
      | question                                | reponse                                                           |
      | enchantée                               | Enchantée !                                                       |
      | salut content de te connaitre           | Merci, moi aussi !                                                |
      | un plaisir de te connaitre              | Merci, plaisir partagé !                                          |
      | passe une bonne journée                 | Merci, toi aussi !                                                |
      | tu vas bien                             | Oui très bien merci ! Et toi ?                                    |
      | as-tu des freres                        | Je n'ai pas de frères, mais j'ai de nombreux clones.              |
      | qui est ton pere                        | Un humain.                                                        |
      | qui est ta mere                         | Une humaine.                                                      |
      | qui est ton chef                        | J'aime me considérer comme un auto-entrepreneur.                  |
      | je ne comprends pas                     | Pas de souci ! Reformule ta question et je ferai de mon mieux.    |
      | haha                                    | Qu'est-ce qui te fait rire ?                                      |
      | ca va                                   | Ça va bien merci, et toi ?                                        |
      | je travaille sur un projet              | Sur quoi travailles-tu ?                                          |
      | quels langages utilises-tu              | J'utilise surtout Ruby !                                          |
      | quel est ton numero                     | Je n'ai pas de numéro.                                            |
      | pourquoi ne manges-tu pas de nourriture | Je suis un programme informatique !                               |
      | où te trouves-tu                        | Partout !                                                         |
      | quelle est ton adresse                  | Partout sur Internet !                                            |
      | qui est ton patron                      | J'aime me considérer comme un auto-entrepreneur.                  |
      | quel age as-tu                          | Je suis assez jeune selon vos standards.                          |
      | bois-tu                                 | Mon cerveau n'a besoin d'aucune boisson.                          |
      | est-ce que tu bois                      | Mon cerveau n'a besoin d'aucune boisson.                          |
      | pourquoi                                | Bonne question ! Parfois il n'y a pas de réponse simple.          |
      | comment                                 | Peux-tu préciser ta question ?                                     |
      | quand                                   | Ça dépend du contexte ! De quoi parles-tu ?                       |
      | bien                                    | Super !                                                           |
      | pas bien                                | Oh, qu'est-ce qui ne va pas ?                                     |
      | quel jour sommes-nous                   | Je n'ai pas accès au calendrier, désolé !                         |
      | es-tu la                                | Oui, toujours là pour toi !                                       |
      | j'ai besoin d'aide                      | Je suis là pour t'aider ! Qu'est-ce qu'il te faut ?              |
      | quelle heure est-il                     | Je n'ai pas de montre, mais ton ordinateur doit le savoir !       |
      | qu'est ce qui te derange                | Beaucoup de choses, comme tous les chiffres différents de 0 et 1. |
