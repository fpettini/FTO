# Directory di lavoro
set working_directory "C:/Users/Utente/OneDrive - dbm.unisi.it/Documents/projects/paper/FTO/simulations/in_off/GMX/stripped"
cd $working_directory

# Prefissi delle traiettorie/strutture
set prefixes {free_DA6_in_stripped free_DA6_off_stripped C6_DA6_in_stripped C6_DA6_off_stripped}

# Dizionario per accumulare le distanze per ogni prefisso
array set data {}

# Calcola e accumula le distanze per ciascuna traiettoria
foreach prfx $prefixes {
    set gro "${prfx}.gro"
    set xtc "${prfx}.xtc"

    # Carica struttura e traiettoria
    mol new $gro waitfor all
    mol addfile $xtc first 0 step 1 waitfor all

    set n_frames [molinfo top get numframes]

    # Selezioni riutilizzabili (aggiornate per frame)
    set sel1 [atomselect top "resname FE2 and name FE2"]
    #set sel2 [atomselect top "resname DA6 and name C10"]
	set sel2 [atomselect top "resname DA6"]
    
	# Lista distanze per questo prefisso
    set data($prfx) {}

    for {set frame 0} {$frame < $n_frames} {incr frame} {
        $sel1 frame $frame
        $sel2 frame $frame

        if {[$sel1 num] == 0 || [$sel2 num] == 0} {
            lappend data($prfx) NaN
        } else {
            set com_site [measure center $sel1 weight mass]
            set com_lig  [measure center $sel2 weight mass]
            set distance [veclength [vecsub $com_site $com_lig]]
            lappend data($prfx) $distance
        }
    }

    $sel1 delete
    $sel2 delete
    mol delete all
}

# Scrive tutto in un unico file, colonne separate per traiettoria
#set fout [open "distance_FE2toC10_all.dist" "w"]
set fout [open "distance_FE2tocomDA6_all.dist" "w"]

# Intestazione
set header "frame"
foreach prfx $prefixes {
    append header " ; $prfx"
}
puts $fout $header

# Trova il numero massimo di frame tra le traiettorie
set max_n 0
foreach prfx $prefixes {
    set len [llength $data($prfx)]
    if {$len > $max_n} { set max_n $len }
}

# Scrive riga per riga: frame ; dist_traj1 ; dist_traj2 ; ...
for {set i 0} {$i < $max_n} {incr i} {
    set line "$i"
    foreach prfx $prefixes {
        set len [llength $data($prfx)]
        if {$i < $len} {
            set val [lindex $data($prfx) $i]
        } else {
            set val "NaN"
        }
        append line " ; $val"
    }
    puts $fout $line
}

close $fout

exit
