Unit UTic2;                        {Algorythme du jeu}

Interface

uses OWindows, WinTypes, WinProcs, Strings, Utic1, Utic3;

{-----------------------------------------------------------------------------------------------}

const cm_Demarre = 303;

{Cette procedure est publique (spécialement pour le programme principal) :}
function titre_Fen(jeu, numF : byte; Participant : TNom) : String;

type

    TPointB = record x, y : ShortInt; end;

PTTTJ = ^TTTJ;
TTTJ = object(TWindow)

    grille : array[1..3, 1..3] of byte;  {(1,1) angle en haut à gauche} {0 : case inoccupé; 1 : case occupé par joueur = 1;...}
    SBrush : HBrush;
    joueur, coup : byte;                 {joueur 1..2}
    gagnant : array[1..2] of byte;
    TJeu, NumFen : byte;
    Stat : statistiques;
    actif : Boolean;

    constructor Init(AParent : PWindowsObject; ATitle : PChar; donnees : TDonnees);
    procedure GetWindowClass(var AWndClass : TWndClass); virtual;
    function GetClassName : PChar; virtual;
    procedure SetUpWindow; virtual;
    procedure Paint(PaintDC : HDC; var PaintInfo : TPaintStruct); virtual;
    procedure controle(g : TPointb; j : byte; dim : TRect);
{    procedure pos_coor(pos : byte; var dim : TRect);
    function coor_pos(x, y, Right, Bottom : word; var case_ : byte) : boolean;}
    procedure WMLButtonUP(var Msg : TMessage); virtual wm_First + wm_LButtonUp;
    procedure ordinateur(dim : TRect);
    procedure Demarrage;
    procedure WMMDIActivate(var Msg : TMessage); virtual wm_First + wm_MDIActivate;
    procedure WMTimer(var Msg : TMessage); virtual wm_First + wm_Timer;
    procedure WMDestroy(var Msg : TMessage); virtual wm_First + wm_Destroy;
    function CanClose : Boolean; virtual;
    procedure cmDemarre(var Msg : TMessage); virtual cm_First + cm_Demarre;
    procedure cmArret(var Msg : TMessage); virtual cm_First + cm_Arret;
    procedure cmStat_Zero(var Msg : TMessage); virtual cm_First + cm_Stat_Zero;
    destructor done; virtual;
end;

var fenetre : array[1..2, 0..255] of boolean;    {1, 0..255 : pour AF; 2, 0..255 : pour FF}

{-----------------------------------------------------------------------------------------------}

Implementation

{$R Utic2.res}

const
      grillage : array[1..5] of real = (8 / 100, 36 / 100, 64 / 100, 92 / 100, 28 / 100);
      {  y
       x   1  2 3  4
         1
             ¦ ¦
         2  - - -           5 = intervalle
            ¦ ¦
         3 - - -
           ¦ ¦
         4
       }

      timer_id = 1;
      time = 1;

function titre_Fen(jeu, numF : byte; Participant : TNom) : String;
const NJeu : array[1..2] of PChar = ('Affront final', 'Face à face');
var s : string;
begin
     str(NumF, s);
     s := StrPas(NJeu[jeu div 5 + 1]) + ' ' + s + ' (' + StrPas(Participant[1]) + ' vs ' + StrPas(participant[2]) + ')'#0;
     Titre_Fen := s;
end;

constructor TTTJ.Init(AParent : PWindowsObject; ATitle : PChar; donnees : TDonnees);
begin
     TWindow.Init(AParent, ATitle);
     coup := 0; {Pour le bon affichage du bouton = le fenêtre devient active avant l'appel à setup}
     TJeu := donnees.TJeu;
     Stat.Nom := Donnees.Nom;
     gagnant[1] := 0; gagnant[2] := 0;
     SBrush := CreateSolidBrush(GetSysColor(COLOR_APPWORKSPACE));
     EnableMenuItem(Menu, cm_Arret, mf_ByCommand or mf_Enabled);
     NumFen := donnees.NFen + 1;
     Fermeture1Fen := False;
     {+1 parce que NFen donne le numéro de la fenêtre pour la détection de l'ouverture de la
     fenêtre dans la variable fenêtre définie de 0 à 255.}
end;

procedure TTTJ.GetWindowClass(var AWndClass : TWndClass);
begin
     TWindow.GetWindowClass(AWndClass);
     AWndClass.hbrBackground := SBrush;
end;

function TTTJ.GetClassName : PChar;
begin
     GetClassName := 'Jeu';
end;

procedure TTTJ.Demarrage;
var dim : TRect;
    nbre : array[0..3] of Char;
    boucle, boucle2 : byte;
begin
     for boucle := 1 to 3 do for boucle2 := 1 to 3 do grille[boucle, boucle2] := 0;
     if Odd(TJeu) then
     begin
          coup := 0;
          joueur := 2;
     end
     else
     begin
          joueur := 1;
          coup := 1;
          GetClientRect(HWindow, dim);
          ordinateur(dim);
     end;
     with Stat do
     begin
          StrCopy(match, Nom[1]);
          StrCat(match, ' vs ');
          StrCat(match, Nom[2]);
          StrCat(match, ' (n°');
          Str(NumFen, nbre);
          StrCat(match, nbre);
          StrCat(match, ')');
          JoueurA := Joueur;
          Redemarrer := False;
     end;
end;

procedure TTTJ.SetupWindow;
begin
     TWindow.Setupwindow;
     with stat do
     begin
          NVictoires[1] := 0;
          NVictoires[2] := 0;
          NParties := 1;
          Temps := 0;
          StrCopy(DGagnant, 'Personne');
     end;
     HFen := HWindow;
     Demarrage;
     Statistique := stat;
     SetTimer(HWindow, Timer_id, Time * 1000, nil);
     InvalidateRect(HScores, @FenStat, false);          {Réaffichage complet}
end;

destructor TTTJ.done;
begin
     fenetre[TJeu div 5 + 1, NumFen - 1] := False;
     EnableMenuItem(Menu, cm_Arret, mf_ByCommand or mf_Grayed); {Ajouter un ligne qui gère cela dans WMDI_Activate}
     DeleteObject(SBrush);
{Au cas où la fenêtre suivante est Scores, il faut penser à ne pas permettre à l'utilisateur de recommencer une partie}
     if HScores <> 0 then OkButton^.Show(sw_Hide);
     EnableMenuItem(Menu, cm_Demarre, mf_ByCommand or mf_Grayed);
     TWindow.Done;
end;

{procedure TTTJ.pos_coor(pos : byte; var dim : TRect);
var z : single;
begin
     dec(pos);
     with dim do begin
          z := Right * grillage[1] + Right * (grillage[2] - grillage[1]) * (pos mod 3);
          Left := round(z);
          z := z + Right * (grillage[2] - grillage[1]);
          Right := round(z);
          z := Bottom - Bottom * grillage[1] - Bottom * (grillage[2] - grillage[1]) * (pos div 3 + 1);
          Top := round(z);
          z := z + Bottom * (grillage[2] - grillage[1]);
          Bottom := round(z);
     end;
end;}

procedure _3x3_coor_(g : TPointB; dim : TRect; var dim2 : TRect); {Coordonnées de la case -> coordonnées de l'écran}
begin
     with dim do
     begin
          dim2.Left := round(Right * grillage[g.x]);
          dim2.Right := Right - dim2.Left;
          dim2.Top := round(Top * grillage[g.y]);
          dim2.Bottom := Bottom - dim2.Top;
     end;
end;

function _coor_3x3_(souris : LongInt; dim : TREct; var g : TPointB) : boolean; {Coordonnes de click -> coordonnées de la case}
begin
     g.x := round(3 * dim.Right * grillage[5] / (LoWord(souris) - 2 * dim.Right * grillage[1])) + 1;
     g.y := round(3 * dim.Bottom * grillage[5] / (HiWord(souris) - 2 * dim.Bottom * grillage[1])) + 1;
     _Coor_3x3_ := (g.x in [1..3]) and (g.y in [1..3]);
end;

{function TTTJ.coor_pos(x, y, Right, Bottom : word; var case_ : byte) : boolean;
var boucle : byte;
    z : single;
begin
     coor_Pos := false;
     z := x - Right * grillage[1];
     if z >= 0 then
     begin
          z := z / Right / (grillage[2] - grillage[1]);
          if trunc(z) <= 2 then
          begin
               case_ := trunc(z) + 1;
               z := y - Bottom * grillage[1];
               if z >= 0 then
               begin
                    z := z / Bottom / (grillage[2] - grillage[1]);
                    if trunc(z) <= 2 then
                    begin
                         case_ := case_ + abs(trunc(z) - 2) * 3;
                         coor_pos := true;
                    end;
               end;
          end;
     end;
end;}

procedure TTTJ.Paint(PaintDC : HDC; var PaintInfo : TPaintStruct);
var dim : TRect;
    NBrush, OBrush : HBrush;
    NPen, OPen : HPen;

    procedure affiche_grille;
    var x, y : real;
    begin
    with dim do begin
         NPen := CreatePen(ps_Solid, right div 100, RGB(0, 0, 0));
         OPen := SelectObject(PaintDC, NPen);
         x := Right * grillage[2]; y := Bottom * grillage[1];           {Dessine deux colonnes}
         MoveTo(PaintDC, round(x),  round(y));
         LineTo(PaintDC, round(x),  Bottom - round(y));
         Moveto(PaintDC, Right - round(x), round(y));
         LineTo(PaintDC, Right - round(x), Bottom - round(y));
         SelectObject(PaintDC, OPen);
         DeleteObject(NPen);
         NPen := CreatePen(ps_Solid, Bottom div 100, RGB(0, 0, 0));
         OPen := SelectObject(PaintDC, NPen);
         x := Right * grillage[1]; y := Bottom * grillage[2];           {Dessine deux lignes}
         MoveTo(PaintDC, round(x), round(y));
         LineTo(PaintDC, right - round(x), round(y));
         MoveTo(PaintDC, round(x), Bottom - round(y));
         LineTo(PaintDC, Right - round(x), Bottom - round(y));
         SelectObject(PaintDC, OPen);
         DeleteObject(NPen);
    end;
    end;

    procedure croix(d1, d2 : TRect);
    var x, y : word;
    begin
         with d1 do
         begin
              x := Right div 20; y := Bottom div 20;
              NPen := CreatePen(ps_Solid, (Right + Bottom) div 60 div 2, RGB(255, 0, 0));
         end;
         OPen := SelectObject(PaintDC, NPen);
         with d2 do
         begin
              MoveTo(PaintDC, Left + x, Top + y);
              LineTo(PaintDC, Right - x, Bottom - y);
              MoveTo(PaintDC, Left + x, Bottom - y);
              LineTo(PaintDC, Right - x, Top + y);
         end;
         SelectObject(PaintDC, OPen);
         DeleteObject(NPen);
    end;

    procedure rond(d1, d2 : TRect);
    var x, y : word;
    begin
         with d1 do
         begin
              x := Right div 20; y := bottom div 20;
              NPen := CreatePen(ps_Solid, (Right + Bottom) div 100, RGB(0, 0, 255));
         end;
         OPen := SelectObject(PaintDC, NPen);
         OBrush := SelectObject(PaintDC, GetStockObject(Hollow_Brush));
         with d2 do
              Ellipse(PaintDC, Left + x, Top + y, Right - x, Bottom - y);
         SelectObject(PaintDC, OBrush);
         SelectObject(PaintDC, OPen);
         DeleteObject(NPen);
    end;

    procedure sinusoide;
    const p = 100;
    var x, y : single;
        pre : word;
    begin
         with dim do begin
              case gagnant[joueur] of
                   11..13 : begin
                                 NPen := CreatePen(ps_Solid, Right div 80, RGB(255, 255, 255));
                                 OPen := SelectObject(PaintDC, NPen);
                                 x := Right * grillage[gagnant[joueur] - 10];
                                 y := Bottom * grillage[1];
                                 MoveTo(PaintDC, round(x), round(y));
                                 x := (x + Right * grillage[gagnant[joueur] - 9]) / 2;
                                 for pre := 1 to p do 
                                     LineTo(PaintDC,
                                         round(x - cos(pre / p * 3 * Pi) * Right * (grillage[2] - grillage[1]) / 2),
                                           round(y + pre / p * (Bottom * grillage[2] * 2 + Bottom * grillage[1])));
                            end;
                   14..16 : begin
                                 NPen := CreatePen(ps_Solid, Bottom div 80, RGB(255, 255, 255));
                                 OPen := SelectObject(PaintDC, NPen);
                                 x := Right * grillage[1];
                                 y := Bottom - Bottom * (grillage[gagnant[joueur] - 12]);
                                 MoveTo(PaintDC, round(x), round(y));
                                 y := y + (Bottom * (grillage[2] - grillage[1]) / 2);
                                 for pre := 1 to p do
                                     LineTo(PaintDC, round(x + Pre / p * (Right * grillage[4] - x)),
                                            round(y - cos(pre / p * 5 * Pi) * Bottom * (grillage[2] - grillage[1]) / 2));
                            end;
                   17 : begin
                             x := (Right + Bottom) / 80 / 2;
                             NPen := CreatePen(ps_Solid, round(x), RGB(255,255,255));
                             OPen := SelectObject(PaintDC, NPen);
                             x := Right * grillage[1];
                             y := Bottom * grillage[4];
                             MoveTo(PaintDC, round(x), round(y));
                             for pre := 1 to p do
                                 LineTo(PaintDC, round(x + pre / p * (Right * grillage[4] - x)),
                                        round(y - pre / p * Bottom * grillage[5] * 3
                                        - sin(pre / p * 10 * Pi) * Bottom * grillage[5] / 2.5));
                        end;
                   else begin
                             x := (Right + Bottom) / 80 / 2;
                             NPen := CreatePen(ps_Solid, round(x), RGB(255,255,255));
                             OPen := SelectObject(PaintDC, NPen);
                             x := Right * grillage[1];
                             y := Bottom * grillage[1];
                             MoveTo(PaintDC, round(x), round(y));
                             for pre := 1 to p do
                                 LineTo(PaintDC, round(x + pre / p * (Right * grillage[4] - x)),
                                        round(y + pre / p * Bottom * grillage[5] * 3
                                        + sin(pre / p * 10 * Pi) * Bottom * grillage[5] / 2.5));
                   end;
              end;
              SelectObject(PaintDC, OPen);
              DeleteObject(NPen);
         end;
    end;

    procedure croix_rond;
    var g : TPointB;
        dim2 : TRect;
    begin
         for g.y := 1 to 3 do for g.x := 1 to 3 do
         begin
             _3x3_coor_(g, dim, dim2);
             case grille[g.x, g.y] of
                  1 : croix(dim, dim2);
                  2 : rond(dim, dim2);
             end;
         end;
    end;

begin
     TWindow.Paint(PaintDc, PaintInfo);
     GetClientRect(HWindow, dim);
     OBrush := SelectObject(PaintDC, GetStockObject(LtGray_Brush));
     OPen := SelectObject(PaintDC, GetStockObject(White_Pen));
     with dim do
          Rectangle(PaintDC, right div 20, bottom div 20, right - right div 20, bottom - bottom div 20);
     SelectObject(PaintDC, OPen);
     SelectObject(PaintDC, OBrush);
     Affiche_Grille;
     croix_rond;
     if gagnant[joueur] >= 11 then sinusoide;
end;

procedure TTTJ.controle(g : TPointB; j : byte; dim : TRect);
begin
end;

procedure TTTJ.WMLButtonUp(var Msg : TMessage);
var rec, dim : TRect;
    g : TPointB;
const CJoueurA : TRect = (Left : 95; Top : 195; Right : 300; Bottom : 223); {Rectangle du joueur actif}

    procedure participant(a : byte);
    var maj : TRect;
    begin
         StrPCopy(stat.DGagnant, Stat.Nom[a]);
         inc(Stat.NVictoires[a]);
         Stat.JoueurA := 0;
         Statistique := stat;
         if HScores <> 0 then with maj do
         begin
              Left := 150; Top := 180; Right := 339; Bottom := 200; {Affichage du dernier gagnant}
              InvalidateRect(HScores, @maj, False);
              Left := 5; Top := 100; Right := 70; Bottom := 180;    {Affichage des pourcentages pour le premier joueur}
              InvalidateRect(HScores, @maj, false);
              Left := 160; Top := 100; Right := 337; Bottom := 180; {Affichage des pourcentages pour le deuxièmes joueur}
              InvalidateRect(HScores, @maj, false);
              InvalidateRect(HScores, @CJoueurA, false);
         end;
    end;

begin
     GetClientRect(HWindow, rec);{ dim := rec;}
     if Coup < 9 then
     begin
          if _coor_3x3_(Msg.LParam, rec, g) and (grille[g.x, g.y] = 0) then
          begin
               inc(coup);
               if (TJeu in [1, 3]) or ((Tjeu = 5) and (joueur = 2)) then {la condition TJeu in [1, 3] n'est pas superfue!}
                    joueur := 1
               else
                    joueur := 2;
               grille[g.x, g.y] := joueur;
               _3x3_Coor_(g, rec, dim);
               Invalidaterect(HWindow, @dim, false);
               controle(g, joueur, rec);
               if (TJeu  <> 5) and (coup < 9) and (gagnant[joueur] < 10) then
               begin
                    joueur := 3 - joueur;
                    if TJeu in [1..2] then begin gagnant[1] := 0; gagnant[2] := 0; end;
                    ordinateur(dim);
                    inc(coup);
               end;
               if gagnant[1] > 10 then
               begin
                    coup := 9; {Parce que la partie peut se terminer avant les 9 coups}
                    if joueur = 1 then participant(1); {Ligne exécutée seulement s'il y a un gagnant}
               end
               else
                   if gagnant[2] > 10 then
                   begin
                        coup := 9; {Parce que la partie peut se terminer avant les 9 coups}
                        if joueur = 2 then participant(2); {Ligne exécutée seulement s'il y a un gagnant}
                   end;
               if coup = 9 then
               begin
                    Stat.JoueurA := 0;
                    if HScores <> 0 then OkButton^.Show(sw_Show);
                    EnableMenuItem(Menu, cm_Demarre, mf_ByCommand or mf_Enabled);
               end
               else
                   Stat.JoueurA := Joueur;
               Statistique := stat;
               if HScores <> 0 then InvalidateRect(HScores, @CJoueurA, false);
          end
          else MessageBeep(0)
     end
     else MessageBeep(0);
end;

procedure TTTJ.ordinateur(dim : TRect);
const coin : array[1..4] of byte = (1, 3, 7, 9);
var rec : TRect;
    adv : byte;
begin
     adv := 3 - joueur;
     if (gagnant[1] = 0) and (gagnant[2] = 0) then
     begin
          if joueur = 2 then
          begin
               if grille[5] = '-' then gagnant[joueur] := 5
               else
                   if (grille[1] = '-') or (grille[3] = '-') or (grille[7] = '-') or (grille[9] = '-') then
                      repeat;
                             gagnant[joueur] := coin[random(4) + 1];
                      until grille[gagnant[joueur]] = '-'
                   else
                       repeat
                             gagnant[joueur] := random(9) + 1;
                       until grille[gagnant[joueur]] = '-';
          end
          else
          repeat
                 gagnant[joueur] := random(9) + 1;
          until grille[gagnant[joueur]] = '-';
          grille[gagnant[joueur]] := pion[joueur];
          pos_coor(gagnant[joueur], dim);
          InvalidateRect(HWindow, @dim, false);
     end
     else
          if gagnant[joueur] <> 0 then
          begin
               rec := dim;
               grille[gagnant[joueur]] := pion[joueur];
               pos_coor(gagnant[joueur], dim);
               InvalidateRect(HWindow, @dim, false);
               controle(rec);
          end
          else
               if gagnant[adv] <> 0 then
               begin
                    rec := dim;
                    grille[gagnant[adv]] := pion[joueur];
                    pos_coor(gagnant[adv], rec);
                    InvalidateRect(HWindow, @rec, false);
                    controle(dim);
               end;
end;

procedure TTTJ.WMMDIActivate(var Msg : TMessage);

    procedure Initiation2;
    var t : TNom20;
        boucle : byte;
        s : string[65];
        victoire : word;
        rec : TRect;
   begin
         if TJeu <> 5 then
            if odd(TJeu) then inc(TJeu) else dec(TJeu);                  {Permutation des types de jeu}
         gagnant[1] := 0; gagnant[2] := 0;                               {gagnant réinitié}
         with stat do
         begin
              inc(NParties);
              t := Nom[1]; Nom[1] := Nom[2]; Nom[2] := t;                     {Permutation des noms}
              victoire := NVictoires[1]; NVictoires[1] := NVictoires[2]; NVictoires[2] := victoire; {Permutation des victoires}
              demarrage;                                                      {Paramètres communs à SetupWindow}
              s := Titre_Fen(TJeu, NumFen, Nom)                              {Attribution d'un nouveau nom à la fenêtre de jeu}
         end;
         SetWindowText(HWindow, @S[1]);
         GetClientRect(HWindow, Rec);
         InvalidateRect(HWindow, @Rec, false);                           {Redessiner la planche de jeu}
   end;

   procedure Mise_a_Zero;
   begin
        if MessageBox(HWindow, 'Etes-vous sûr de vouloir remettre tous les compteurs à zéro?',
                      'Attention', mb_YesNo or mb_IconExclamation) = idYes then
        with stat do
        begin
             Temps := 0;
             NVictoires[1] := 0; NVictoires[2] := 0;
             NParties := 1;
             StrCopy(DGagnant, 'Personne');
        end;
        Stat_Zero := True;
   end;


begin
     if Bool(Msg.WParam) then
        if Fermeture1Fen then CloseWindow
        else
        begin                                {La fenêtre devient active}
          actif := true;
          HFen := HWindow;
          EnableMenuItem(Menu, cm_Arret, mf_ByCommand or mf_Enabled);
          if Redemarrer then Initiation2 {Demande d'engager une nouvelle partie}
          else
              if Stat_Zero then Mise_a_Zero;
          Statistique := Stat;
          if HScores <> 0 then
          begin
               if coup >= 9 then
               begin
                    OkButton^.Show(sw_Show);
                    EnableMenuItem(Menu, cm_Demarre, mf_ByCommand or mf_Enabled);
               end
               else
               begin
                    OkButton^.Show(sw_Hide);
                    EnableMenuItem(Menu, cm_Demarre, mf_ByCommand or mf_Grayed);
               end;
               InvalidateRect(HScores, @FenStat, false); {Réaffichage complet des statistiques}
          end;
     end
     else actif := false;      {perte du focus}
end;

procedure TTTJ.WMTimer(var Msg : TMessage);
const rec : TRect = (Left : 78; Top : 67; Right : 78 + 13 * 3; Bottom : 67 + 23);{Rectangle du temps}
      rec2 : TRect = (Left : 5; Top : 3; Right : 337; Bottom : 55);
begin
     if actif and (coup < 9) then
     begin
          inc(Stat.Temps);
          if HScores <> 0 then
          begin
               Statistique := Stat;
               InvalidateRect(HScores, @rec, false);
          end;
     end;
end;

function TTTJ.CanClose : Boolean;
var Dscore : LongInt;
    choix : byte;
    messages : array[0..130] of Char;
begin
     if Fermeture1Fen and (TJeu < 5) then
        with Stat do
        begin
             if StrComp(Nom[1], 'Destroyer') = 0 then JoueurA := 1 else JoueurA := 2;
             if JoueurA = 1 then DScore := NVictoires[1] - NVictoires[2] else DScore := NVictoires[2] - NVictoires[1];
             if Dscore < -1 then Choix := 1
             else
                 case DScore of
                 -1 : choix := 2;
                  0 : choix := 3;
                  1 : choix := 4;
                 else
                     choix := 5;
                 end;
             Fermeture1Fen := False;
             if LoadString(HInstance, Choix, Messages, 130) > 0 then
                CanClose := MessageBox(HWindow, Messages, 'Vous êtes sur le point d''arrêter le match',
                                       mb_YesNo or mb_IconQuestion) = idYes
             else CanClose := True;
        end
        else
            CanClose := True;
end;

procedure TTTJ.cmDemarre(var Msg : TMessage);
begin
     Redemarrer := true;
     WMMDIActivate(Msg);
end;

procedure TTTJ.WMDestroy(var Msg : TMessage);
begin
     KillTimer(HWindow, timer_Id);
     TWindow.WMDestroy(Msg);
end;

procedure TTTJ.cmArret(var Msg : TMessage);
begin
     Fermeture1Fen := True;
     CloseWindow;
end;

procedure TTTJ.cmStat_Zero(var Msg : TMessage);
begin
     Stat_Zero := True;
     WMMDIActivate(Msg);
end;

end.

{-----------------------------------------------------------------------------------------------

  Coup <  9 = la partie n'est pas encoree ternimée
  Coup >= 9 = la partie est terminée

  Le temps tourne toujours si la fenêtre active n'est pas une TWindow.

  Ajouter éventuellement un effet 3D aux objects

  Styliser le fond des fenêtres comme celles de Borland Pascal

  Permettre de jouer avec les touches de 1 à 9

  Eviter que le coup favori de ma soeur fonctionne.

}