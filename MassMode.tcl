# ModeMass
# * Ajout, Suppresion de mode et Kick en masse.
# *
# * @author Nami-Doc
# * @version 0.1.3
# * @server EpikNet
# * @api
# * Remerciements:
# * caline pour l'idée
namespace eval ModeMass {
	variable single "!mode"
	variable chan "!m"
	variable auth "n|n"
	# Modes autorisés ~ k = kick, for mass-kick
	variable allowed {v h e o a q k}
	# pseudos protegés, exemple: {NomDubot MonPseudo PseudoBotServ}
	variable protected_pseudos {Aphrodite Apollon Ares Artemis Asclepios Calliope Centaure Cerbere Chrion Clio Cronos Demeter Dike Dionysos Eole Erato Euterpe Hebe Hephaistos Hera Hestia Melopmene Neree Ocean Ouranos Pan Polymnie Polymorphee Pontos Psyche Rhea Silene Sphinx Terpsichore Thalie Uranie Fayetooh Nami-Doc}
	# Autoriser l'ajout de mode ?
	variable allow_add 1
	# Autoriser la suppresion ?
	variable allow_del 1
	# Autoriser le kick de masse ?
	variable allow_masskick 1
	# Message lors du globalKick
	variable masskick_msg "GlobalKick par %nick%"
}

## Begin TCL - Don't touch this code unless you know what you're doing (and you know TCL)

bind pub $ModeMass::auth $ModeMass::single ModeMass::single
bind pub $ModeMass::auth $ModeMass::chan ModeMass::chan

proc ModeMass::_checkMode {mode} {
	foreach mode_ [set [namespace current]::allowed] {
		if {$mode_ eq $mode} {
			return 1
		}
	}
	return 0
}

proc ModeMass::_getAction {add} {
	if {$add eq "" || $add eq "on" || $add eq "add" || $add eq "+"} {
		set add "+"
	} elseif {$add eq "off" || $add eq "del" || $add eq "-"} {
		set add "-"
	} else {
		return 0
	}
	return $add
}
proc ModeMass::single {nick host handle chan arg} {
	_process $nick [lindex $arg 0] [lindex $arg 1] [lindex $arg 2]
}
proc ModeMass::chan {nick host handle chan arg} {
	_process $nick [join [chanlist $chan] ","] [lindex $arg 0] [lindex $arg 1]
}

proc ModeMass::_process {$nick $name $modes $arg} {
	set msg [_set [lindex $arg 0] [lindex $arg 1] [lindex $arg 2]]
	if {$msg != ""} {
		puthelp "NOTICE $nick :$msg"
	}
}
proc ModeMass::_set {$names $modes $adds} {
	foreach mode [explode $modes ","] {
		putlog "mode: $mode, names: $nnames, adds: $adds"
		# traitement du type
		if {$adds eq ""} {
			set adds "+"
		}

		foreach add [split $adds ","] {
			if {[set add [_getAction $add]] eq 0 && $m != "k"} {
				return "Type invalide"
			}
			# vérification de paramètres
			if {($add eq "-" && ![set [namespace current]::allow_del]) || ($add eq "+" && ![set [namespace current]::allow_add]) || ($m eq "k" && ![set [namespace current]::allow_masskick])} {
				return "Impossible."
			}

			# vérification des modes
			if {![_checkMode $m]} {
				return "Mode invalide."
			}
			if {$m eq "k"} {
				foreach kick_nick [split $names ","] {
					putkick $chan $kick_nick $reason
				}
			} else {
				foreach mode_nick [split $names ","] {
					pushmode $chan "[set add][set m]" $mode_nick
				}
			}
		}
	}
	flushmode $chan
}

putlog "massmode par Nami-Doc chargé"
