# Nami tools
# * Boîte à outils pour eggdrop
# *
# * @version 0.0.1
# * @irc-chan EpikNet
# * @api

# randomNick (c) MenzAgitat - Modified
# Merci à su_e_do_is pour son avis et à MenzAgitat pour son aide

namespace eval namiTools {
	#############################
	#	     PARAMETRES         #
	#############################
	# maitre(s) (séparés par des virgules) (laisser vide si seul le flag compte) !! CECI EST UN HOST !!
	variable master "EpiK-YourHost"

	# chans sur lequel MegahalReloaded est actif
	variable chans $::listChans_IA

	variable logChan "#botsfun"

	# commandes (séparées par un espace)
	variable serv_cmd "!serv !serveur"
	variable sprotch_cmd "!ecrase"
	variable randomkick_cmd "!randomshoot"
	variable timekick_cmd "!timekick !tk"
	variable timeban_cmd "!timeban !tb"

	# doit-il être utilisé avec MegahalController (de Su_e_do_is)
	variable megahal_controller 0
	# doit-il être utilisé avec MegahalInterface (de MenzAgitat)
	variable megahal_interface 1

	# niveau nécéssaire
	variable serv_level "bmn|n"
	variable sprotch_level $serv_level
	variable randomkick_level $serv_level
	variable join_level $serv_level
	variable timekick_level $serv_level
	variable timeban_level $serv_level

	# nick qui ne peuvent rien faire
	variable parias {buzai}

	# le bot doit-il attendre un peu avant de lancer les commandes ? (augmente la crédibilité)
	variable realityMode 1

	# protections: pseudos (pour la défense)
	variable protected_pseudos {Nami-Doc Cerbere Fayetooh}

	# commandes agressives que le bot ne peut pas utiliser pour se défendre
	variable extra_agressives_cmds {!kb}
	# commandes agressives que le bot peut utiliser pour se défendre
	variable agressives_cmds "$sprotch_cmd !kick"

	# Do not touch to this unless you know what you do !
	variable phrases {
		{Bien visé %kicker% :)}
		{Tu reviendras %kicked% ? %kicker% à l'air de t'aimer !}
		{C'est fou, un courant d'air à emporté %kicked% !}
		{%me%Admire la manière dont %kicked% s'est fait expulser !}
		{C'est fou, %kicked% est parti :o}
		{%kicked%, enfin ! %kicker% à quelque chose à te dire !}
	}

	variable defense_phrases {
		{Va voir ailleurs si j'y suis %nick% !}
		{Tu t'es cru où %nick% ?}
		{Il se passe quoi dans ta tête %nick% ? Tu crois avoir le droit de de me toucher ?}
		{Nan mais nawak %nick% !}
		{Dommage %nick%, je sais me défendre !}
		{Tu ne croyais pas t'en tirer comme ça %nick% j'espère !}
	}



	################################################################
	#                                                              #
	# DO NOT MODIFY ANYTHING BELOW THIS BOX IF YOU DON'T KNOW TCL  #
	#                                                              #
	################################################################
	proc uninstall {args} {
		putlog "Désallocation des ressources de \002foobar\002..."
		foreach binding [lsearch -inline -all -regexp [binds *[set ns [string range [namespace current] 2 end]]*] " \{?(::)?$ns"] {
			unbind [lindex $binding 0] [lindex $binding 1] [lindex $binding 2] [lindex $binding 4]
		}
		namespace delete [namespace current]
	}

	set agressives_cmds [split $agressives_cmds " "]

	variable defense_commands ""


	bind pub $serv_level [set [namespace current]::serv_cmd] [namespace current]::serv

	foreach agressive_cmd $agressives_cmds {
		bind pub - $agressive_cmd [namespace current]::defense
		set defense_commands "$agressive_cmd %nick% %reason%||$defense_commands"
	}
	foreach extra_agressive_cmd $extra_agressives_cmds {
		bind pub - $extra_agressive_cmd [namespace current]::defense
	}

	bind pub - "!host" namiTools::getHost

	set defense_commands [split $defense_commands "||"]

	variable in_defense 0
}

## EVENTS BINDING ##
# Ok, this is not really...beautiful
foreach cmd_ [split $namiTools::sprotch_cmd " "] {
	bind pub $namiTools::sprotch_level $cmd_ namiTools::ecrase
}
foreach cmd_ [split $namiTools::serv_cmd " "] {
	bind pub $namiTools::serv_level $cmd_ namiTools::serv
}
foreach cmd_ [split $namiTools::randomkick_cmd " "] {
	bind pub $namiTools::randomkick_level $cmd_ namiTools::randomKick
}
foreach cmd_ [split $namiTools::timekick_cmd " "] {
	bind pub $namiTools::timekick_level $cmd_ namiTools::timeKick
}

bind pub -|- "!help" namiTools::helpSay
bind pub -|- "!aide" namiTools::helpSay

bind pub -|- "!nespresso" {puthelp "PRIVMSG $_pub4 :What else ?";#}
bind evnt - prerehash ::namiTools::uninstall
foreach cmd_ [split $namiTools::timeban_cmd " "] {
	bind pub $namiTools::timeban_level $cmd_ namiTools::timeBan
}
bind pub m|m ".mod" ::namiTools::modere
bind pub m|m ".mods" ::namiTools::modo

bind pub m|m "!paria" ::namiTools::managementParia

proc namiTools::managementParia {nick host hand chan arg} {
	
}

proc namiTools::modo {nick host hand chan arg} {
	set modes [lindex $arg 0]
	foreach act [split $modes ","] {
		if {[lsearch -exact {s a o h v} $act] != -1} {
			putquick "PRIVMSG #chan :$nick > Le mode n'est pas valide"
			return
		}
		foreach nick [explode "," [lindex $arg 1]] {
			pushmode $chan +$act $nick
		}
	}
	flushmode $chan
}

proc namiTools::modere {nick host hand chan arg} {
	set act [lindex $arg 0]
	set target [lindex $arg 1]
	set nicks [split $target ","]
	if {$act eq "a"} {
		if {[lindex $arg 1] eq ""} {
			puthelp "PRIVMSG $chan :Utilisation: .mod a pseudo,pseudo,..."
		} else {
			set cmd "add"
			set exact 1
			set type [lindex $arg 2]
			if {$type eq "--remove" || $type eq "--rem"} {
				set cmd "del"
			}
			set nick ""
			foreach onChanNick [chanlist $chan] {
				if {[string match $target $onChanNick]} {
					set nick "$nick,$onChanNick"
				}
			}
			set target $nick
			foreach nick $nicks {
				putquick "PRIVMSG Gaia :akick $chan $cmd $nick"
				if {$cmd eq "del"} {
					putquick "PRIVMSG [set [namespace current]::logChan] :akick $chan $nick (remove)"
					pushmode $chan "-b" "$nick!*@*"
				} else {
					putquick "PRIVMSG [set [namespace current]::logChan] :akick $chan $nick (adding)"
				}
			}
			flushmode $chan
			putquick "PRIVMSG Gaia :akick $chan enforce"
		}
	} elseif {$act eq "i"} {
		foreach nick $nicks {
			puthelp "PRIVMSG [set [namespace current]::logChan] :Inviting $nick on $chan"
			putquick "INVITE $nick $chan"
		}
	} elseif {$act eq "b"} {
		set action "+"
		if {[lindex $arg 2] eq "--remove"} {
			set action "-"
		}
		foreach pseudo $nicks {
			putquick "PRIVMSG [set [namespace current]::logChan] :ban: $action $pseudo"
			pushmode $chan "[set action]b" "[set pseudo]!*@*"
		}
		flushmode $chan
	} elseif {$act eq "k"} {
		set reason [lrange $arg 2 end]
		if {$reason eq ""} {
			set reason "Requested ($nick)"
		}
		foreach pseudo $nicks {
			putkick $chan $pseudo $reason
		}
	} else {
		puthelp "PRIVMSG $chan :\00314\002Utilisation:\002 .mod \037a\037/\037i\037/\037b\037 \037\[pseudo.join ','\]\037\003"
	}
}

proc namiTools::_getSmileysRegexp {} {
	return "(:|=)(d|s|/|\(|')+"
}

proc namiTools::_secureRegexp {txt} {
	return [join [split $txt ""] "\\"]
	set txt [string map {"+" "\\+"} $txt]
	return $txt
}

bind pub n|n "!say" namiTools::say
## END EV'BINDING ##

## DEBUG MODE ##
proc namiTools::say {nick host hand chan arg} {
	set destination [lindex $arg 0]
	set text [lrange $arg 1 end]
	putquick "PRIVMSG $destination :$text" -next
}
## END DebugM ##

proc namiTools::serv {nick host hand chan arg} {
	if {$arg eq "on"} {
		topicwarden::command $nick $host $hand $chan "Serveur \037ON\037"
	} elseif {$arg eq "off"} {
		topicwarden::command $nick $host $hand $chan "Serveur \037OFF\037"
	} else {
		puthelp "PRIVMSG $chan :Utilisation: \037!serv\037 \002\0034On\003\002/\002\0034Off\003\002"
	}
}

proc namiTools::ecrase {nick host hand chan arg} {
	set kicknick [lindex $arg 0]
	set _reason [lrange $arg 1 end]
	set timer [[namespace current]::_rand 1000 1500]
	set phrase [[namespace current]::_listRand [set [namespace current]::phrases]]
	set phrase [regsub -all "%kicked%" $phrase $kicknick]
	set phrase [regsub -all "%kicker%" $phrase $nick]
	
	set phrase [regsub -all "%me%" $phrase "\001ACTION "]
#Corrected by MenzAgitat:(doesn't work) =>
#  set phrase [regsub -all "^%me%(.*)" $phrase "\001ACTION \1\001"]

#	set phrase [regsub -all "%me" $phrase "\001ACTION"]

	if {$_reason != ""} {
		variable reason " - Raison: \037$_reason\037"
	} else {
		variable reason ""
	}
#	putquick "KICK $chan $kicknick :\002\0033Ecrasé par \037$nick\037$reason\003\002" -normal
	if {$kicknick eq $::nick} {
		putquick "PRIVMSG $chan :$nick > T'y croyais vraiment ?"
		return
	} else {
		putkick $chan $kicknick "\002\0033Ecrasé par \037$nick\037$reason\003\002"
	} 
	if {$namiTools::realityMode} {
		after $timer
	}
	if {!$namiTools::in_defense && ([set [namespace current]::megahal_interface] && ![megahal_interface::shutup? $chan])} {
		puthelp "PRIVMSG $chan :$phrase"
	}
}

proc namiTools::_listRand {elements} {
	return [lindex $elements [rand [llength $elements]]]
}


proc namiTools::defense {nick host hand chan arg} {
	set pseudo [lindex $arg 0]
	if {$pseudo eq $nick} {
		putkick $chan $nick "Requested"
		return
	}
	if {[lsearch -nocase [set [namespace current]::protected_pseudos] $pseudo] eq -1} {
		return
	}
	set [namespace current]::in_defense 1
	set phrase [[namespace current]::_listRand [set [namespace current]::defense_phrases]]
	set timer [[namespace current]::_rand 250 750]
	set phrase [regsub -all "%nick%" $phrase $nick]

	if {[set [namespace current]::realityMode]} {
		after 25
	}
	if {$pseudo eq $::nick} {
		# on ne dit la phrase QUE si c'est le bot qui se venge
		putquick "PRIVMSG $chan :!ecrase $nick $phrase" -next
	}
	if {[set [namespace current]::realityMode]} {
		after $timer
	}
	[namespace current]::ecrase $pseudo $host $hand $chan "$nick $phrase"
	set [namespace current]::in_defense 0
}

proc namiTools::randomKick {nick host hand chan arg} {
	if {$arg != ""} {
		set arg " - Raison: \037$arg\037"
	}
	set kicknick [[namespace current]::randomNick $chan]
	putquick "KICK $chan $kicknick :\002\0033Randomkické par \037$nick\037$arg\003\002"
}

# debug
proc namiTools::getHost {nick host hand chan arg} {
	puthelp "PRIVMSG $chan :\002$nick\002: Ton host est \002\0034 $host\003\002"
}

proc namiTools::randomNick {chan} {
	#set users_list [lreplace [set users [chanlist $chan -b|]] [set index [lsearch $users $nick]] $index]
	#prev. line replaced with
	set users_list [chanlist $chan -b|]
	foreach pseudo_p [set [namespace current]::protected_pseudos] {
		set users_list [lreplace $users_list [set index [lsearch $users_list $pseudo_p]] $index]
	}
	if {[set [namespace current]::megahal_controller]} {
		foreach pseudo_ps $megahal_c::botlist {
			set users_list [lreplace $users_list [set index [lsearch $users_list $pseudo_ps]] $index]
		}
	}
	set users_list [lreplace $users_list [set index [lsearch $users_list $::botnick]] $index]
	if {[llength $users_list] > 0} {
		return [lindex $users_list [rand [llength $users_list]]]
	} else {
		if {[set [namespace current]::realityMode]} {
			after [[namespace current] 250 750]
		}
		puthelp "PRIVMSG $chan :et tu veux kicker qui exactement, hein ?"
		return
	}
}

proc namiTools::paria {nick} {
	if {[lsearch -exact [set [namespace current]::parias] $nick] != -1} {
		return 1
	}
	return 0
}

proc namiTools::timeKick {nick host hand chan arg} {
#	set timeKick [rand 15000]
	set kickNick [lindex $arg 0]
	set reason [lrange $arg 1 end]
	set temps [[namespace current]::_rand 250 5000]

	if {$reason ne ""} {
		set reason "\0033, \003\037\0033$reason\003\037"
	}

	after $temps
	set temp [expr int([::tcl::mathfunc::floor [expr $temps / 100]])]
	[namespace current]::ecrase $nick $host $hand $chan "$kickNick \0034B0oM\003\037\0039($temp)\003$reason"
}

proc namiTools::debanInvit {chan nick} {
	putquick "PRIMSG [set [namespace current]::logChan] :debanning ..."
	putquick "MODE $chan -b $nick!*@*"
	putquick "INVITE $nick $chan"
}

proc namiTools::timeBan {nick host hand chan arg} {
	set banNick [lindex $arg 0]
	if {!([onchan $banNick $chan])} {
		return
	}
	set banTime [lindex $arg 1]
	set banReasonPerso [lrange $arg 2 end]
	set sec_plural ""
	if {$banTime > 1} {
		set sec_plural "s"
	}
	set banReason "\002\0033Bannis \037$banTime minute$sec_plural\037 par \037$nick\037, "
	if {$banReason != ""} {
		set banReason "$banReason\Raison: \037$banReasonPerso\037"
	}
	set banReason "$banReason.\003\002"

	putquick "mode $chan +b $banNick!*@*"
	putquick "privmsg [set [namespace current]::logChan] :banning $banNick => $banReason for $banTime minutes"
	putquick "KICK $chan $banNick :$banReason"
	timer $banTime [list [namespace current]::debanInvit $chan $banNick]
}

proc namiTools::helpSay {nick host hand chan arg} {
	if {[[namespace current]::paria $nick]} { return }
	set cmd [lindex $arg 0]
	set structure "(Inconnue)"
	set level "public"
	if {$arg eq "say"} {
		set structure "\$chan \$text. Fait dire au bot une phrase"
		set level "owner"
	} elseif {$arg eq "dec2bin" || $arg eq "dec2hex" || $arg eq "dec2oct" || $arg eq "bin2dec" || $arg eq "bin2hex" || $arg eq "bin2oct" || $arg eq "bin2str" || $arg eq "hex2dec" || $arg eq "hex2bin" || $arg eq "hex2oct" || $arg eq "hex2str" || $arg eq "oct2bin" || $arg eq "oct2dec" || $arg eq "oct2hex" || $arg eq "oct2str" || $arg eq "str2hex" || $arg eq "str2oct" || $arg eq "str2bin" || $arg eq "mirc2egg"} {
		set structure "\$aConvertir. Converti \$aConvertir dans le langage demandé (dec=décim, hex=héxadécim, bin=bin, mirc=client IRC,oct=octet, str=string(chaine de caractère), egg=eggdrop (type de bot))"
	} elseif {$arg eq "acronyme"} {
		set structure "\$initiales. Donne le/les acronyme(s) de \$initiales"
	} elseif {$arg eq "vdm"} {
		set structure ". Donne une viedemerde au hasard"
	} elseif {$arg eq "chuck"} {
		set structure ". Donne une chucknorrisfacts au hasard"
	} elseif {$arg eq "traduire"} {
		set structure "\$langues \$phrase/mot. exemple: !$arg en-fr hot. Traduit un mot/une phrase d'une langue à une autre"
	} elseif {$arg eq "dtc" || $arg eq "bashfr"} {
		set structure "\[\$numero]. Donne une citation de danstonchat au hasard ou ayant l'id \$numero. Si \$numero vaut last, la dernière quote crée est donnée. La quote est changée toutes les 2 minutes"
	} elseif {$arg eq "bash.org"} {
		set structure "\[\$numero]. Donne une citation de bash.org au hasard ou ayant l'id \$numero. Si \$numero vaut last, la dernière quote crée est donnée. La quote est changée toutes les 2 minutes / search [\$texte]. Recherche une quote sur bash.org content \$texte / \[ON ou OFF]. Active/désactivé la commande bash.org"
		set level "public / public / owner"
	# BEGIN Quote #
	} elseif {$arg eq "quote"} {
		set structure "\$numero \[\$canal]. Affiche la citation n°\$numero. \$canal vaut par défaut le canal actuel"
	} elseif {$arg eq "findquote"} {
		set structure "\[-all OU #canal] \$criteres. Rechercher une citation. Mettez des \" \" autour de vos arguments de recherche pour rechercher l'expression exacte. Utilisez le paramètre -all pour effectuer une recherche globale dans les bases de données de TOUS les chans OU précisez le chan sur lequel vous souhaitez effectuer la recherche."
	} elseif {$arg eq "randquote"} {
		set structure ". Donne une citation au hasard"
	} elseif {$arg eq "quoteinfo"} {
		set structure "\$numero. Donne des informations sur la citation n°\$numero"
		set level "owner"
	} elseif {$arg eq "addquote"} {
		set structure "\$quote. Ajoute la citation avec le texte \$quote"
		set level "owner"
	} elseif {$arg eq "deletedquoteinfo"} {
		set structure "\$numero. Affiche les informations sur la quote supprimée n°\$numero"
		set level "owner"
	} elseif {$arg eq "undelquote"} {
		set structure "\$numero. Restaure la citation n°\$numero"
		set level "owner"
	} elseif {$arg eq "forcedelquote"} {
		set structure "\$numero. Supprime la citation n°\$numero, même si vous n'en êtes pas l'auteur"
		set level "owner"
	} elseif {$arg eq "cancelquote"} {
		set structure ". Annule l'enregistrement de la dernière citation"
		set level "owner"
	# END   Quote #
	} elseif {$arg eq "ecrase"} {
		set structure "\$nick \[\$reason]. Kick la personne specifiée dans le canal"
		set level "owner"
	} elseif {$arg eq "topic"} {
		set structure "\$topic. Si \$topic vaut mask, change le masque du chan. Si \$topic vaut on/off, active/désactive la gestion de topic sur ce canal. Si \$topic vaut reset, remet à zéro %variable%. Si \$topic n'est pas défini, affiche le topic. Sinon, change %variable%"
		set level "owner"
	} elseif {$arg eq "randomshoot" || $arg eq "randomkick"} {
		set structure "\[\$raison]. Kick une personne au hasard dans le canal"
		set level "owner"
	} elseif {$arg eq "story"} {
		set structure "[\$nom1] \[\$nom2] \[\$nom...] \[\$nom7]. Donne une histoire de 1 à 7 personnes (aléatoire si appelé sans paramètres)."
	} elseif {$arg eq "crise"} {
		set structure "\[\on/off]\. Met le mode crise à on/off (on si non specifié)"
		set level "owner"
	# BEGIN maths_egg #
	} elseif {$arg eq "trinome"} {
		set structure "\$a \$b \$c (où \$a est non nul). Donne les valeurs pour lequel le polinome s'annule et les racines"
	} elseif {$arg eq "distance"} {
		set structure "\$xA \$yA \$xB \$yB. Donne la distance entre deux points"
	} elseif {$arg eq "estrectangle"} {
		set structure "\$AB \$AC \$BC. Dis si le triangle ABC est rectangle ou non (et donne l'hypothènuse)"
	} elseif {$arg eq "hypothenuse"} {
		set structure "\$AB \$AC. Donne l'hypothènuse (BC) dans un triangle rectangle"
	} elseif {$arg eq "adj"} {
		set structure "\$coté1 $hypothènuse. Donne la longueur du 2eme côté"
	# END   maths_egg #
	} elseif {$arg eq "dico"} {
		set structure "\$mot. Donne la signification du mot \$mot"
	# BEGIN MDS #
	} elseif {$arg eq "lire"} {
		set structure ". Donne la liste des messages reçu (et des accusés de reception)"
	} elseif {$arg eq "msg"} {
		set structure "\$destinataire1>\[,\$destinataire2,...\] \$message. Envoie le message \$msg aux destinataires (séparés une virgule)"
	} elseif {$arg eq "messages"} {
		set structure ". Donne la liste des messages"
	} elseif {$arg eq "lu"} {
		set structure "\$ID. Marque le message n°\$ID comme lu"
	# END   MDS #
	} elseif {$arg eq "meteo"} {
		set structure "\$ville. Donne la météo pour la ville \$ville"
	# BEGIN OMGYSU! #
	} elseif {$arg eq "vg"} {
		set structure "$durée. Impose le silence sur le canal. Si $duree n'est pas donné, le mode ne s'enlèvera pas seul. Si \$durée vaut off, le silence sera enlevé."
		set level "owner"
	} elseif {$arg eq "chut"} {
		set structure "\$nick \$durée. Empêche \$nick de parler pendant \$durée minutes (3 par défaut)."
		set level "owner"
	# END   OMGYSU! #
	} elseif {$arg eq "oracle"} {
		set structure "\$question. Pose une question à l'oracle"
	} elseif {$arg eq "mode"} {
		set structure "\$mode \$type. Donne le mode \$mode à tout le monde (mode k = kick tout le monde). \$type: non renseigné (par défaut +) OU + OU on: ajoute le mode. - OU off: enlève le mode"
		set level "owner"
	} elseif {$arg eq "m"} {
		set structure "\$nick \$mode \$type. Donne le mode \$mode à la personne \$nick (k = kick). \$type: non renseigné (par défaut +) OU + OU on: ajoute le mode. - OU off: enlève le mode"
		set level "owner"
	} elseif {$arg eq "help" || $arg eq "aide"} {
		set structure ". Affiche l'aide"
	# BEGIN Roulette #
	} elseif {$arg eq "roulette"} {
		set structure ". Démarre la roulette"
	} elseif {$arg eq "roulette.stop"} {
		set structure ". Arrête la roulette"
		set level "owner"
	} elseif {$arg eq "roulette.on"} {
		set structure ". Active la roulette"
		set level "owner"
	} elseif {$arg eq "roulette.off"} {
		set structure ". Désactive la roulette"
		set level "owner"
	} elseif {$arg eq "pan"} {
		set structure ". Tire un roue à la roulette (elle doit être lancée !)"
	# END   Roulette #
	# BEGIN keskidi #
	} elseif {$arg eq "keskidi"} {
		set structure "\$nick. Donne une des phrases que \$nick à dit dernièrement. Les jokers (*) sont activés."
	} elseif {$arg eq "keskifai"} {
		set structure "\$nick. Donne une des actions que \$nick à fait dernièrement. Les jokers (*) sont activés"
	# END   keskidi #
	} elseif {$arg eq "calc" || $arg eq "calcule"} {
		set structure "\$expression. Calcule l'expression \$expression"
	# BEGIN Euro #
	} elseif {$arg eq "euro"} {
		set structure "\$somme. Convertis la somme \$somme d'euros en francs"
	} elseif {$arg eq "franc"} {
		set structure "\$somme. Convertis la somme \$somme de francs en euros"
	# END   Euro #
	# BEGIN MOD' #
	} elseif {$arg eq ".mod"} {
		set structure "\$type [i = invite/b = ban/a = a-kick/k = kick] \$pseudo.join ','. Invite/Bannis/Akick/Kick les pseudos $pseudo, séparés par une virgule"
		set level "owner"
	} elseif {$arg eq "timeban"} {
		set structure "\$nick \$temps \[\$raison\]. Bannis \$nick pour \$temps minutes, avec possibilité de spécifier une raison."
		set level "owner"
	# END MOD'   #
	# BEGIN Incith-Google #
	# ... not now
	# END Incith-Google   #
	# BEGIN stats #
	# ... not now
	# END STATS   #
	# OTHER #
	} elseif {$arg eq "register"} {
		set structure "- Pour enregistrer votre pseudo, tapez /msg Themis REGISTER {mot de passe} {email}. Vous devrez ensuite vous connecter en faisant /msg Themis IDENTIFY {mot de passe}"
		set level ""
	} elseif {$arg eq "" || $arg eq "--list"} {
		set cmds {!oracle !meteo !lire !msg !lu !messages !dico !adj !hypothenuse !estrectangle !distance !story !acronyme !vdm !dtc !bash.org !chuck !traduire !mirc2egg !estrectangle !quote !quoteinfo !addquote !delquote !findquote !dec2bin !dec2hex !dec2oct !bin2dec !bin2hex !bin2oct !bin2str !hex2dec !hex2bin !hex2oct !hex2str !oct2bin !oct2dec !oct2hex !oct2str}
		set cmds2 {!str2hex !str2oct !str2bin !mirc2egg !roulette !pan !keskidi !keskifai !franc !euro !google !images !local !groups !news !books !video !scholar !googlefight !youtube !locate !gamespot !translate !dailymotion !gamefasq !blogsearch !ebay !ebayfight !bestest !review !wikipedia !crap !mininova !igame !myvids !trends !aide !top10 !ttop10 !top20 !ttop20}
		set cmds3 {!stats !count !stat !tstat !place !tplace !wordstats !topwords !seen :actions !nespresso}
		set priv_cmd {.compile !randomshoot !forcedelquote !deletedquoteinfo !cancelquote !undelquote !ecrase !crise !topic !vg !chut !mode !m !roulette.stop !roulette.on !roulette.off .mod !timeban}

		set open_cmd [join $cmds ", "]
		set open_cmd2 [join $cmds2 ", "]
		set open_cmd3 [join $cmds3 ", "]
		set priv_cmd [join $priv_cmd ", "]
		set s_pub "s"
		set s_priv "s"
		if {[llength $cmds] eq 1} {
			set s_pub ""
		}
		if {[llength $priv_cmd] eq 1} {
			set s_priv ""
		}
		puthelp "NOTICE $nick :\00314\002Commandes libres\002 ([expr [llength $cmds] + [llength $cmds2]] documentées$s_pub):\003 $open_cmd,"
		puthelp "NOTICE $nick :$open_cmd2"
		puthelp "NOTICE $nick :$open_cmd3"
		puthelp "NOTICE $nick :\00314\002Commandes privées\002 ([llength $priv_cmd] documentée$s_priv):\003 $priv_cmd"
		return
	} else {
		puthelp "PRIVMSG $chan :\00314La commande n'existe pas.\003"
		return
	}

	if {$structure != "" && [string index $structure 0] != "."} {
		set structure " $structure"
	}
	if {$level != ""} {
		set level "\003 \00315\002Niveau\002: $level\003"
	}
	puthelp "NOTICE $nick :\00314\002HELP \002$cmd\002\002: \037!$cmd\037$structure.$level"
}

proc namiTools::_rand {min max} {
	if {[expr $min > $max]} {
#	inversion
		set _min $max
		set min $max
		set max $_min
	}
	return [expr $min + [rand [expr $max - $min]]]
}
