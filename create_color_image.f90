
!========================================================================
!
!                   S P E C F E M 2 D  Version 5.1
!                   ------------------------------
!
!                         Dimitri Komatitsch
!          Universite de Pau et des Pays de l'Adour, France
!
!                          (c) January 2005
!
!========================================================================

  subroutine create_color_image(donnees_image_color_2D,iglob_image_color_2D,NX,NY,it,cutvect)

! routine d'affichage du deplacement sous forme d'image en couleurs

! to display the snapshots : display image*.gif

! when compiling with Intel ifort, use " -assume byterecl " option to create binary PNM images

  implicit none

  include "constants.h"

  integer NX,NY,it

  double precision cutvect

  integer, dimension(NX,NY) :: iglob_image_color_2D

  double precision, dimension(NX,NY) :: donnees_image_color_2D

  integer ix,iy,R,G,B,dixmilliers,milliers,centaines,dizaines,unites,reste,current_rec

  double precision amplitude_max,valeur_normalisee

  character(len=100) nom_fichier,system_command

! create temporary image files in binary PNM P6 format (smaller) or ASCII PNM P3 format (easier to edit)
  logical, parameter :: BINARY_FILE = .true.

! ASCII code of character '0' and of carriage return character
  integer, parameter :: ascii_code_of_zero = 48, ascii_code_of_carriage_return = 10

! ouverture du fichier image
  write(nom_fichier,"('OUTPUT_FILES/image',i6.6,'.pnm')") it

! ouvrir le fichier
  if(BINARY_FILE) then

    open(unit=27,file=nom_fichier,status='unknown',access='direct',recl=1)
    write(27,rec=1) 'P'
    write(27,rec=2) '6' ! ecrire P6 = format d'image PNM binaire
    write(27,rec=3) char(ascii_code_of_carriage_return)

! compute and write horizontal size
    reste = NX

    dixmilliers = reste / 10000
    reste = reste - 10000 * dixmilliers

    milliers = reste / 1000
    reste = reste - 1000 * milliers

    centaines = reste / 100
    reste = reste - 100 * centaines

    dizaines = reste / 10
    reste = reste - 10 * dizaines

    unites = reste

    if(dixmilliers > 0) then
      write(27,rec=4) char(dixmilliers + ascii_code_of_zero)
    else
      write(27,rec=4) ' '
    endif

    if(milliers > 0) then
      write(27,rec=5) char(milliers + ascii_code_of_zero)
    else
      write(27,rec=5) ' '
    endif

    if(centaines > 0) then
      write(27,rec=6) char(centaines + ascii_code_of_zero)
    else
      write(27,rec=6) ' '
    endif

    write(27,rec=7) char(dizaines + ascii_code_of_zero)
    write(27,rec=8) char(unites + ascii_code_of_zero)
    write(27,rec=9) ' '

! compute and write vertical size
    reste = NY

    dixmilliers = reste / 10000
    reste = reste - 10000 * dixmilliers

    milliers = reste / 1000
    reste = reste - 1000 * milliers

    centaines = reste / 100
    reste = reste - 100 * centaines

    dizaines = reste / 10
    reste = reste - 10 * dizaines

    unites = reste

    if(dixmilliers > 0) then
      write(27,rec=10) char(dixmilliers + ascii_code_of_zero)
    else
      write(27,rec=10) ' '
    endif

    if(milliers > 0) then
      write(27,rec=11) char(milliers + ascii_code_of_zero)
    else
      write(27,rec=11) ' '
    endif

    if(centaines > 0) then
      write(27,rec=12) char(centaines + ascii_code_of_zero)
    else
      write(27,rec=12) ' '
    endif

    write(27,rec=13) char(dizaines + ascii_code_of_zero)
    write(27,rec=14) char(unites + ascii_code_of_zero)
    write(27,rec=15) char(ascii_code_of_carriage_return)

! nombre de nuances
    write(27,rec=16) '2'
    write(27,rec=17) '5'
    write(27,rec=18) '5'
    write(27,rec=19) char(ascii_code_of_carriage_return)

! block of image data starts at sixteenth character
    current_rec = 20

  else

    open(unit=27,file=nom_fichier,status='unknown')
    write(27,"('P3')") ! ecrire P3 = format d'image PNM ASCII
    write(27,*) NX,NY  ! ecrire la taille
    write(27,*) '255'  ! nombre de nuances

  endif

! calculer l'amplitude maximum
  amplitude_max = maxval(abs(donnees_image_color_2D))

! dans le format PNM, l'image commence par le coin en haut a gauche
  do iy=NY,1,-1
    do ix=1,NX

! regarder si le pixel est defini ou non (au dessus de la topographie par exemple)
      if(iglob_image_color_2D(ix,iy) == -1) then

! utiliser couleur bleu ciel pour afficher les zones non definies situees au dessus de la topo
        R = 204
        G = 255
        B = 255

! supprimer les petites amplitudes considerees comme du bruit
      else if (abs(donnees_image_color_2D(ix,iy)) < amplitude_max * CUTVECT) then

! use black background where amplitude is negligible
          R = 0
          G = 0
          B = 0

      else

! definir les donnees comme etant le deplacement normalise entre [-1:1]
! et converti a l'entier le plus proche
! en se rappelant que l'amplitude peut etre negative
        valeur_normalisee = donnees_image_color_2D(ix,iy) / amplitude_max

! supprimer valeurs en dehors de [-1:+1]
        if(valeur_normalisee < -1.d0) valeur_normalisee = -1.d0
        if(valeur_normalisee > 1.d0) valeur_normalisee = 1.d0

! utiliser rouge si deplacement positif, bleu si negatif, pas de vert
        if(valeur_normalisee >= 0.d0) then
          R = nint(255.d0*valeur_normalisee**POWER_DISPLAY_COLOR)
          G = 0
          B = 0
        else
          R = 0
          G = 0
          B = nint(255.d0*abs(valeur_normalisee)**POWER_DISPLAY_COLOR)
        endif

      endif

! ecrire l'image en couleur
      if(BINARY_FILE) then

! first write red
        write(27,rec=current_rec) char(R)
        current_rec = current_rec + 1

! then write green
        write(27,rec=current_rec) char(G)
        current_rec = current_rec + 1

! then write blue
        write(27,rec=current_rec) char(B)
        current_rec = current_rec + 1

      else

        write(27,"(i3,' ',i3,' ',i3)") R,G,B

      endif

    enddo
  enddo

! fermer le fichier
  close(27)

! open image file and create system command to convert image to more convenient format
  write(system_command,"('cd OUTPUT_FILES ; convert image',i6.6,'.pnm image',i6.6,'.gif ; rm image',i6.6,'.pnm')") it,it,it

! call the system to convert image to GIF
  call system(system_command)

  end subroutine create_color_image
