#############################################################################
# CustoMegahal																#
# @author Nami-Doc															#
# @bot Fayetooh																#
# @server EpikNet															#
#																			#
# CustoMegahal est un script pour faire des réponses						#
#  à votre propre mesure pour votre bot										#
# Il permet aussi de faire un système d'actions, avec :[act]				#
#  et :list/:actions pour avoir la liste des actions						#
#																			#
# Version 1.0																#
# Changelog																	#
#  1.2.0																	#
#	Modification de Megahal_Interface pour appeler CustoMegahal::tg			#
#	 quand le/la bot doit se taire											#
#	CustoMegahal "remplace" mc_respond dans Megahal_Interface				#
#	Ajout d'une possibilité de savoir si le/la bot est en shutup? avec une	#
#	 liste de réponses associées (shutupON et shutupOFF)					#
#	Déplacement des timers vers le namespace timer::						#
#	Modification du format des actions pour faire {{a b} {c d}} 			#
#	 devenir {a b c d}														#
#	Ajout du type de log 2: PartyLine log									#
#	Ajout du match "Salut/hi/etç... vous" (si "vous" n'est pas sur le canal)#
#	 qui répond "nous"														#
#  1.1.0																	#
#	Ajout d'une unique procédure de debug									#
#	Ajout de pas mal de logs si log ON (colorés)							#
#	Ajout de la possibilité d'utiliser les variables de match:: dans les	#
#	 REGEXPs, en mettant {nom}, qui deviendra donc $match::nom !			#
#  1.0.1																	#
#	Compatible uniquement avec MegahalInterface,							#
#	 avec la gestion de réponse (à la place de MC.Respond)					#
#  1.0.0																	#
#	Refonte de la gestion des actions, voir la documentation				#
#	Refonte de la gestion des réponses. avec un namespace pour les réponses	#
#	 et une variable avec le nom dans le namespace, et une liste des		#
#	 déclencheurs (REGEXP)													#
#	Modification de l'API avec une méthode sendReply qui prend en paramètre	#
#	 le canal, le pseudo et les possibilitées de réponses.					#
#	 Les variables utilisables dans les réponses sont:						#
#		- %randNick% (pseudo au hasard dans le canal, ni %nick% ni %bot)	#
#		- %nick%, le pseudo qui a déclenché le déclencheur					#
#		- %bot%, le pseudo de la bot										#
#		- %me%, qui stipule que c'est une action (équivalent de /me)		#
#	 Elle log aussi dans le canal de log la réponse envoyée,				#
#	  qui l'a déclenchée et où												#
#	Ajout de la compatibilité MegahalInterface, avec shutup? en API			#
#  0.0.4:																	#
#	Ajout d'un bride avec MegahalController,								#
#	 avec possibilité de le désactiver										#
#  0.0.3:																	#
#	Ajout d'un parsage d'action, à la main									#
#	Ajout d'un détecteur d'insultes											#
#  0.0.2a:																	#
#	Ajout de la possibilité de définir le canal de log						#
#  0.0.2:																	#
#	Ajout de "salut" et "quoi" (parsage primaire)							#
#	Ajout de la possiblité de logger										#
#  0.0.1:																	#
#	Première version														#
#	Parsage de "cmb", "ctb" et "cmbdtc"										#
#############################################################################
namespace eval CustoMegahal {
	# logger ? 0 pour non, 1 pour oui: dans le canal définis en dessous, 2 pour la partyLine
	variable log 0
	# canal pour afficher les logs
	variable logChan "#botsfun"

	#FORMAT: nomAction~Action1|Action2|Action3(tiré au hasard)~Action si sur la bot 1|2|3(tiré au hasard)
	# NOTE: si l'action sur la bot n'existe pas, un message basique est affiché et la procédure s'arrête
	# NOTE²: si l'action sur la bot est % (act~ACT1|ACT2~%), ça prend sur les actions normales
	variable actions {
		{mord {"%me% mord %actNick%" "%me% met un coup de dents à %actNick%" "%me% mort bien fort %nick%" "%me% commence à courir vers %actNick% et ... %randNick% se fait bouffer à la place de %actNick% ! Désolé !"} {"!kick %nick% T'approches pas --\"" "Du calme %nick% ..."}}
		{cafe {"%me% offre un café à %actNick%" "%me% aurait bien aimé offrir un café à %actNick%, mais il n'a pas les sous. Il les prends donc à %randNick%"} "%"}
		{moka {"%me% offre une tasse de moka à %actNick%"} "%"}
		{suicide {"%actNick% à gagné une corde :D ! Et il s'en sert ! Dit merci à %nick%, %actNick% !"}}
		{baffe {"%me% mets une grosse baffe à %actNick%"}}
		{dej {"%me% donne un p'tit dej à %actNick%"} "%"}
		{pendre {"%me% pend %actNick% avec une superbe corde, jantes cromées etç. La classe %actNick% !"}}
		{clope {"%me% donne une clope à %actNick% et l'allume avec le briquet de %randNick%"}}
		{fouette {"%me% fouette bien fort %actNick% (l)" "%me% mets des grands coups de fouets à %actNick%, pendant que %randNick% bave !"}}
		{champagne {"%me% offre le champagne à tout le monde ! Et du brut !" "%me% offre une coupe à %actNick% ! c'est %randNick% qui paye, pas de panique :p !"}}
		{console {"%me% offre un ourse peluche à %actNick% pour le consoler. Pleure plus va" "%me% voudrait bien consoler %actNick%, mais a peur de mouiller son super pull"}}
	}

	# les différentes réponses, sous la forme {réponse 1} {réponse 2}
	# la liste des variables utilisable est dans le changelog, v1
	namespace eval replies {
		variable citation {
			{C'est malin %nick%}
			{Tss ...}
			{%me% se tais}
			{%me% ne parlera plus, vu que des gens comme %nick% l'observent !}
			{Et moi j'ai trouvé ça: <%nick%> J'en ai une minuscule :/}
			{C'est pas moi qui ai dit ça ! ça doit être %randNick%}
			{Je ne parlerais qu'en présence de mon avocat !}
			{Z'êtes sûr que j'ai dit ça :o ?}
		}
		variable amour {
			{Bah pas moi %nick%}
			{!kick %nick% Tout seul alors :)}
			{%me% s'en fiche}
		}
		variable pardon {
			{mouais ...}
			{Tu veux que je te pardonne pour quoi %nick% ?}
			{!kick %nick% Pas de pardon pour les boulets !}
			{%me% ignore %nick%}
		}
		variable pourquoi {
			{Parce que !}
			{En quoi ça te concerne %nick% ?}
			{!kick %nick% Mêle-toi de tes affaires, tu veux.}
			{Bah passque ... Puis voila kwa.}
			{Parce que c'est comme ça et puis c'est tout.}
			{}
		}
		variable repondMoi {
			{J'ai pas envie %nick%}
			{Demande-donc à %randNick% ...}
			{La réponse est 42 \o/}
			{}
		}
		variable repond {
			{!kick %nick% Mais laisse-le tranquille !}
			{osef %nick% ...}
			{pas grave %nick% ...}
			{}
			{}
		}
		variable merci {
			{de rien %nick%}
			{ça fait 50€ %nick% :D}
			{c'était un plaisir :) !}
			{}
		}
		variable mechant {
			{Ué, j'le suis}
			{!kick %nick% La preuve !}
			{T'as encore rien vu %nick% (: !}
			{Héwé %nick%, et c'est pas le pire (l)}
			{Ouais, d'ailleurs j'adore tyranniser %randNick% :D}
			{}
			{}
		}
		variable dieu {
			{On parle de moiiii ?}
			{On m'appelle ?}
			{Qu'y-a-t'il mes fidèles :) ?}
			{}
			{}
		}
		variable nonRien {
			{Huuuun c'est malin %nick% --}
			{HAHA POWNED %randNick%}
			{}
			{}
		}
		variable salut {
			{Salut %nick% ^^}
			{%me% boude %nick%}
			{%me% donne 20cts à %randNick% pour qu'il dise bonjour à %nick% à sa place x°}
			{Yep %nick% :)}
			{Yo %nick% !}
			{Plop %randNick% ... Heu %nick% ^^'}
			{}
			{}
		}
		variable question {
			{!kick %nick% Tu crois que je ne sais pas à quoi tu penses ?}
			{mmh ?}
			{non %nick% ?}
		}
		variable questionSimple {
			{Je sonne occupé, merci de rappeler plus tard}
			{Nooon %nick% ?}
			{hmm ?}
		}
		variable exclamation {
			{He, j'ai rien fait !}
			{Pas tout de suite %nick%, je suis occupé}
			{%me% masse %nick%}
		}
		variable serieux {
			{Mais je rigole pas %nick% !}
			{%me% ignore %nick%, puisqu'il ne la croit pas}
			{Demande à %randNick%, il est témoin !}
			{Bah oui c'est vrai %nick% -_-}
			{Deviiiiiine %nick% :D !}
		}
		variable sante {
			{Mouais et toi %nick% ?}
			{ça va, ça va, Imhotep.}
			{ça passe %nick%, et toi ?}
			{Mal, et de ta faute -_-}
			{}
		}
		variable smileXD {
			{><}
			{--}
			{}
			{}
		}
		variable smileHan {
			{XD}
			{x°}
			{:D}
			{}
			{}
		}
		variable lol {
			{\o/}
			{lol}
			{lolilol}
			{:') !}
			{}
			{}
			{}
		}
		variable tg {
			{!kick %nick% --"}
			{!randomshoot QUI A DIT CA ?}
			{><}
			{><}
			{:(}
			{ça va, ça va ...}
			{u_u}
			{Mais bien sûr %nick%}
			{}
			{}
		}
		#"
		variable pasCompris {
			{Pas grave %nick% ...}
			{Rendors-toi %nick% ^^'}
			{Viens %nick%, %randNick% va t'expliquer :p}
		}
		variable merci {
			{np}
			{np %nick% ^^}
			{ça fait 50$ %nick% \o/}
			{}
		}
		variable desole {
			{mouais ...}
			{...}
			{J'te pardonne PAS %nick% !}
			{%me% ignore %nick%}
			{C'est ça %nick%, tu veux aussi me faire croire que c'est de la faute de %randNick% ?}
			{}
		}
		variable etAlors {
			{Non, rien \o/.}
			{Rien rien %nick%, dors}
			{%me% lève les yeux au ciel}
			{}
		}

		variable shutupON {
			{OUI !}
			{Ouais.}
			{Ouais.}
			{Oui}
			{Oui}
			{Oui}
			{}
			{}
			{}
		}
		variable shutupOFF {
			{Pourquoi %nick%, tu voudrais :( ?}
			{non :o}
			{Ménon :p}
			{}
			{}
		}
		variable dieu {
			{On parle de moi ?}
			{Ouiiiii %nick% ?}
			{}
		}
	}
	# don't modify anything below this line, unless you know what you do
	# exemple:
	# nom_de_la_variable_dans_::replies {"REGEXP déclencheur 1" "REGEXP déclencheur 2" "REGEXP ..."}
	# NOTE: vous pouvez utiliser des variables de match::, par exemple pour utiliser $match::salut, mettez {salut} ;-)
	variable match {
		sante {"\[scç\]a+ va+ %bot% \\?"}
		serieux {"^{serieux} %bot% ?\[A-Za-z0-9'\"-_\]{0,3} ?\\?"}
		citation {"^{temps}.+<@?%bot%> "}
		pourquoi {"{pourquoi}"}
		repond {"r(é|e)pond !"}
		repondMoi {"r(é|e)pond %bot% ?!*"}
		nonRien {"non, rien(?: \o/)? %bot%"}
		questionSimple {"^%bot% ?$"}
		exclamation {"^%bot% !$"}
		merci {"merci %bot%"}
		mechant {"{mechant} %bot%" "%bot% *,? *{mechant}"}
		amour {"{amour} {0,1}(ma)? %bot%"}
		pardon {"^(pardon|desole|désole|desolé|désolé|dsl|dzl) +%bot%"}
		nonRien {"(quoi|hein|heu|répète|repete|répéte) %bot% {0,1}\\??"}
		pasCompris {"^pas compris(| %bot%)$" "^rien compris ?.*{emote}? ?!?"}
		merci {"^merci %bot%"}
		desole {"^d(e|é)+so+l+(e|é)+ %bot%"}
		etAlors {"e+t+ a+lo+rs %bot% \\?"}	
		smileXD {"xd"}
		smileHan {"(\\>\\<|--|-_-)"}
		lol {"(l|\\\\)+(o+|a+w|u|o+w+)(l|/)+"}
		dieu {"dieu"}
	}
	namespace eval match {
		# Specials matchs
		#@todo move to {} ?
		variable serieux "(?:tu penses?|sérieux?|serieux?|srx|vraiment|tu crois?)"
		variable temps "(\\\[|\\()(\[0-9\]{2}(:|\.)?){2,3}(\\\]|\\))"
		variable pourquoi "p+(o+u*|a+u+)r(kw+a+|quo+i+|quw+a+)"
		variable salut "^(?:s?a?lu+t?|y\[uo\]+p+|yp+|hi|hel+o+|co*u*co*u*|bo+n(?:jo+u+r|so+i+r)) (\[A-Za-z0-9\\^-_\]*)"
		variable tg "(chut|ta gueule|tag+le|ferme-la|ferme la|tagueule|tg|tais-toi)"
		variable mechant "(méchante|mechante|meshante|méshante|mayshante|vilaine)"
		variable amour "(jtm|je t\'a+i+m+e+|\(l\)|I? ?love|<3|:3|=3)"
		variable emote "(?:\[ueéè><_'\"=\\-\]{2,4})"
	}

	namespace eval timer {
		# Enabled module time
		# exemple (with hello on 45):
		# <00h00m00s> [test] Salut !
		# <00h00m01s> {BOT} Salut test !
		# <00h00m15> [test2] Salut !
		# <00h00m15> [test3] Salut !
		#after 45 seconds ...
		# <00h00m46> [Naab] Salut !
		# <00h00m47> {BOT} Salut Naab !
		# !!! OR !!!
		# <00h00m46> [Naab] Salut test !
		# <00h00m47> {BOT} Salut test !
		#(the bot sees the pseudo and tell HIM hello)
		variable hello 120
		variable what 70
	}

	# Insults list
	variable insultes {enfoir salaud salope batard connard " con " "conne " " pd " tafiol pute "trav " "travelo" suceu bite baise nike nique}
	# Channels where swears/insults are ignored
	variable ignoreInsults {}

	# do not modify anything below this line
	variable inWhat 0
	variable inHello 0
}
bind pubm - * ::CustoMegahal::_filter

proc CustoMegahal::debug {txt} {
	set log [set [namespace current]::log]
	if {$log eq 0} {
		return
	} elseif {$log eq 1} {
		putquick "PRIVMSG [set [namespace current]::logChan] :$txt"
	} elseif {$log eq 2} {
		putlog $txt
	}
}
proc CustoMegahal::sendReply {chan nick possibilities} {
	set sentence [namiTools::_listRand $possibilities]
	# si c'est une phrase vide (on ne notice même pas en logchan)
	if {$sentence eq ""} { return }
	set randNickList [chanlist $chan]
	# si il n'y a pas que le bot + l'utilisateur sur le chan
	if {[llength $randNickList] != 2} {
		set randNick $nick
		while {$randNick eq $nick || $randNick eq $::botnick} {
			set randNick [namiTools::_listRand $randNickList]
		}
	} else {
		set randNick "{RAND_NICK}"
	}
	set sentence [string map [split "%nick% $nick %chan% $chan %me% \001ACTION %randNick% $randNick %bot% $::botnick" " "] $sentence]
	putquick "PRIVMSG $chan :$sentence"
	set ::megahal_interface::check_mc_respond 1
	debug "On $chan, with $nick: $sentence"
}

proc CustoMegahal::_filter {nick host hand chan text} {
	set arg [split $text " "]

	if {[regexp -nocase "([join [set [namespace current]::insultes] |])" $text matched]
	 && [lsearch -exact [set [namespace current]::ignoreInsults] $chan] eq -1} {
		debug "$nick@$chan insulte $matched"
		putkick $chan $nick "Veuillez rester correct (*$matched*)"
		return
	}
	if {[namiTools::paria $nick]} { return }

	set firstChar [string index $arg 0]
	if {$firstChar eq ":"} {
		# action
		set choosedAction [string range [lindex $text 0] 1 end]
		if {$choosedAction eq "list" || $choosedAction eq "actions"} {
			set acts ""
			foreach action [set [namespace current]::actions] {
				lappend acts :[lindex $action 0]
			}
			if {$acts eq {} || [namiTools::paria $nick]} {
				putquick "PRIVMSG $chan :\00314\002Aucune action disponible\002.\003"
			} else {
				set acts [join $acts ", "]
				putquick "PRIVMSG $chan :\00315\002Actions disponibles\002 ([llength $acts]):\003\00314 $acts.\003"
			} 
			return
		} else {
			foreach act [set [namespace current]::actions] {
				if {[lindex $act 0] eq $choosedAction} {
					set msg [namiTools::_listRand [lindex $act 1]]
					set actNick [lindex $arg 1]
					if {$actNick eq $::botnick} {
						if {[llength $act] > 2} {
							set msg [lindex $act 2]
							if {$msg != "%"} {
								# action spéciale
								set msg [namiTools::_listRand $msg]
							}
						} else {
							puthelp "PRIVMSG $chan :Pas envie $nick ..."
							return
						}
					}
					set meAct $nick
					if {$actNick eq "" || $actNick eq $nick} {
						# self-reference / nick empty
						set actNick $nick
						set meAct "\001ACTION"
					}
					if {![onchan $actNick $chan]} {
						return
					}
					if {$meAct eq "\001ACTION"} {
						set msg "$msg\001"
					}
					set try 0
					while 1 {
						set randNick [namiTools::_listRand [chanlist $chan]]
						if {($randNick != $actNick && $randNick != $::nick) || $try > 5} {
							break
						}
						incr try 1
					}
					set msg [string map [split "%me% $meAct %nick% $nick %randNick% $randNick %actNick% $actNick" " "] $msg]
					putquick "PRIVMSG $chan :$msg"
					return
				}
			}
		}
		return
	}

	if {[regexp -nocase "Tu bo+u+des $::nick \\?" $text]
	 || [regexp -nocase "$::nick tu bo+u+des \\?" $text]} {
		#Using shutup? instead of canTalk? because canTalk? will never be false
		#That's also the reason for being in ::_filter instead of ::process:, the second is
		# never used if !canTalk?
		if {[::megahal_interface::shutup? $chan]} {
			sendReply $chan $nick [set [namespace current]::replies::shutupON]
		} else {
			sendReply $chan $nick [set [namespace current]::replies::shutupOFF]
		}
		return
	}
}
proc CustoMegahal::shutup {nick host hand chan text} {
	# Ok, this method is launched by my version of Megahal_Interface when !-shutup-!-ing
	sendReply $chan $nick [set [namespace current]::replies::tg]
}
proc CustoMegahal::process {nick host hand chan text} {
	if {[namiTools::paria $nick]} { return }

	set arg [split $text " "]
	set firstChar [string index $text 0]

	foreach prefix [split $::megahal_interface::command_prefixes ""] {
		if {$firstChar eq $prefix} { return }
	}

	debug "--- \002\0037NEW INSTANCE\003\002"
	foreach {matchName match} [set [namespace current]::match] {
		debug "-- \002\0038MATCH\003 $match\002"
		foreach matches $match {
			debug "- \00315MATCHES:\003 $matches"
			set inlineMatches [regexp -all -inline -- "{(\[a-z\]+)}" $matches]
			if {$inlineMatches != ""} {
				debug "\00314Inline:\003 $inlineMatches"
				foreach {__m m} $inlineMatches {
					debug "\00312Processing\003 \00311$m:\003 \00310before\003=$matches"
					debug "\0032Char Map:\003 \002FROM:\002 {$m} \002TO:\002 [set [namespace current]::match::[set m]]"
					set replaceList {}
					lappend replaceList "{$m}"
					lappend replaceList [set [namespace current]::match::[set m]]
					set matches [string map $replaceList $matches]
					debug "\00312Processing\003 \00311$m:\003 \00310after\003=$matches"
				}
			}
			set matches [string map [split "%bot% $::botnick %nick% $nick %chan% $chan" " "] $matches]
			debug "\00314After mapping:\003 $matches"
			if {[regexp -nocase $matches $text]} {
				debug "\0034\002FINDED !\002\0034"
				sendReply $chan $nick [set [namespace current]::replies::[set matchName]]
				return
			}
			debug "- \00315END MATCHES\003"
		}
		debug "-- \0038\002END MATCH\002\003"
	}
	debug "--- \002\0037END INSTANCE\003\002"

	if {[regexp -nocase [set [namespace current]::match::salut] $text total pseudo]
	 && ![set [namespace current]::inHello]} {
		if {[onchan $pseudo $chan] && $pseudo != $::nick} {
			# on remplace $nick par $pseudo pour les salutations ;-)
			set nick $pseudo
		} else {
			# qui nous dit que personne n'a un nick "vous" (exemple) :p ?
			if {$pseudo eq "vous"} {
				set nick "nous"
			}
		}
		set [namespace current]::inHello 1
		utimer [set [namespace current]::timer::hello] [list set [namespace current]::inHello 0]
		sendReply $chan $nick [set [namespace current]::replies::salut]
		return
	}
}
