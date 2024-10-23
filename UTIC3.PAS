Unit UTic3;                       {Affichage des statistiques}

Interface

Uses ODialogs, OWindows, WinTypes, WinProcs, Strings, Utic1;

{-----------------------------------------------------------------------------------------------}

const cm_Scores = 402;
      cm_Veille = 301;
      cm_Stat_Zero = 302;
      cm_Ouvrir = 101;   {Il faut encore implémenter la méthode!}
      cm_Arret = 102;
      cm_Enregistrer = 103; {Encore                                  }
      cm_Enr_Sous = 104;    {       aucune                           }
      cm_Imprimer = 105;    {              méthode                   }
      cm_Setup = 106;       {                      n'est             }
      cm_Imprimante = 107;  {                            implémentée.}
      FenStat : TRect = (Left : 5; Top : 57; Right : 337; Bottom : 225); {Fenêtre des statistiques}
      En_tete : array[0..11] of Char = 'Tic Tac Toe';

type PScores = ^Scores;
     Scores = object(TWindow)

            TitleBMP, NbresBMP : HBitMap;
            SBrush : HBrush;

            constructor Init(AParent : PWindowsObject; ATitle : PChar);
            procedure GetWindowClass(var AWndClass : TWndClass); virtual;
            function GetClassName : PChar; virtual;
            procedure SetUpWindow; virtual;
            procedure Paint(PaintDC: HDC; var PaintInfo: TPaintStruct); virtual;
            procedure idOk(var Msg : TMessage); virtual id_First + id_OK;
            destructor Done; virtual;
            procedure cmStat_Zero(var Msg : TMessage); virtual cm_First + cm_Stat_Zero;
            procedure cmArret(var Msg : TMessage); virtual cm_First + cm_Arret;
            function titreBMP : HBitmap;
     end;

     Statistiques = record Nom : TNom;
                           match : array[0..100] of char;
                           NVictoires : array[1..2] of Word;
                           NParties, temps : Word;
                           DGagnant : array[0..20] of Char;
                           JoueurA : byte;
                    end;

var HScores, HFen : HWnd;
    Statistique : Statistiques;
    OkButton : PButton;
    Menu : HMenu;
    Redemarrer, Stat_Zero, Fermeture1Fen : boolean;

{-----------------------------------------------------------------------------------------------}

Implementation

{$R Utic3.res}

const id_Nbres = 'Nbres';
      bmHeight = 46;
      bmWidth = 315;

constructor Scores.Init(AParent : PWindowsObject; ATitle : PChar);
var cm_boucle : byte;
begin
     TWindow.Init(AParent, ATitle);
     EnableMenuItem(Menu, cm_Scores, mf_ByCommand or mf_Grayed);
     EnableMenuItem(Menu, cm_Veille, mf_ByCommand or mf_Enabled);
     EnableMenuItem(Menu, cm_Stat_Zero, mf_ByCommand or mf_Enabled);
     for cm_boucle := cm_Arret to cm_Imprimante do EnableMenuItem(Menu, cm_boucle, mf_ByCommand or mf_Enabled);
     with Attr do
          with FenStat do
          begin
               OkButton := New(PButton, Init(@Self, id_OK, 'Engager une nouvelle partie',
                               left, bottom + 5, right - 5, 32, true));
               w := Right + 13;
               h := Bottom + 70;
          end;
     NbresBMP := LoadBitmap(HInstance, PChar(id_Nbres));
     SBrush := CreateSolidBrush($0000FF64);
end;

procedure Scores.GetWindowClass(var AWndClass : TWndClass);
begin
     TWindow.GetWindowClass(AWndClass);
     AWndClass.hbrBackground := SBrush;
end;

function Scores.GetClassName : PChar;
begin
     GetClassName := 'Scores';
end;

procedure Scores.SetUpWindow;
begin
     TWindow.SetUpWindow;
     HScores := HWindow;
     OkButton^.Show(sw_Hide);
     TitleBMP := TitreBMP;
end;

procedure Scores.Paint(PaintDC: HDC; var PaintInfo: TPaintStruct);

    procedure titre;
    var MemDC : HDC;
        OBitmap : HBitmap;
    begin
         MemDC := CreateCompatibleDC(PaintDC);
         OBitmap := SelectObject(MemDC, TitleBMP);
         BitBlt(PaintDC, 12, 5, bmWidth, bmHeight, MemDC, 0, 0, srcCopy);
         SelectObject(MemDC, OBitmap);
         DeleteDC(MemDC);
    end;

    procedure commentaire;
    var l : Integer;
        Title : array[0..100] of Char;
        Pen, OPen : HPen;
        Brush, OBrush : HBrush;
    begin
         Pen := CreatePen(ps_Solid, 2, $0);        {Rectangle pour le titre}
         OPen := SelectObject(PaintDC, Pen);
         Brush := CreateSolidBrush(GetNearestColor(PaintDC, $00CB2EB4));
         OBrush := SelectObject(PaintDC, Brush);
         with FenStat do RoundRect(PaintDC, Left, 3, Right, 55, 25, 25);
         SelectOBject(PaintDC, OBrush);
         DeleteObject(Brush);
         SelectObject(PaintDC, OPen);
         DeleteObject(Pen);
         Pen := CreatePen(ps_Solid, 1, $00FF6400);        {Rectangle du tableau d'affichage}
         OPen := SelectObject(PaintDC, Pen);
         Brush := CreateSolidBrush($00007FFF);
         OBrush := SelectObject(PaintDC, Brush);
         with FenStat do rectangle(PaintDC, Left, Top, Right, Bottom);
         SelectOBject(PaintDC, OBrush);
         DeleteObject(Brush);
         SelectObject(PaintDC, OPen);
         DeleteObject(Pen);
         Pen := CreatePen(ps_Solid, 1, $00FFFFFF);        {Rectangle pour les nombres digitaux}
         OPen := SelectObject(PaintDC, Pen);
         OBrush := SelectObject(PaintDC, GetStockObject(Black_Brush));
         rectangle(PaintDC, 75, 63, 120, 93);
         rectangle(PaintDC, 285, 63, 330, 93);
         SelectOBject(PaintDC, OBrush);
         SelectObject(PaintDC, OPen);
         DeleteObject(Pen);
         SetTextColor(PaintDC, RGB(0, 0, 0));
         SetBkMode(PaintDC, Transparent);
         TextOut(PaintDC, 10, 70, 'Temps :', 7);
         TextOut(PaintDC, 170, 70, 'N# de la partie :', 17);
         TextOut(PaintDC, 10, 180, 'Dernier vainqueur :', 19);
         TextOut(PaintDC, 10, 200, 'Joueur actif :', 14);
         SetTextAlign(PaintDC, ta_Center);
         TextOut(PaintDC, 167, 120, 'nombre de victoires', 19);
         TextOut(PaintDC, 167, 140, 'victoires / parties', 19);
         TextOut(PaintDC, 167, 160, 'victoire / adversaire', 21);
    end;

    procedure pourcent(a : LongInt; b : LongInt; Flags, x, y : Word);
    var temp : array[0..7] of Char;
    begin
         if b = 0 then StrPCopy(temp, '0.00%')
         else
         begin
              Str(a / b * 100:0:2, temp);
              StrCat(temp, '%');
         end;
         SetTextAlign(PaintDC, Flags);
         TextOuT(PaintDC, x, y, temp, strlen(temp));
    end;

    procedure victoire(d : LongInt; Flags, x, y : Word);
    var temp : array[0..7] of Char;
    begin
         SetTextAlign(PaintDC, Flags);
         Str(d, temp);
         TextOut(PaintDC, x, y, temp, StrLen(Temp));
    end;

    procedure digital(d : word; x : word);
    const W = 13;
          H = 23;
    var OBitmap : HBitmap;
        MemDC : HDC;
    begin
         MemDC := CreateCompatibleDC(PaintDC);
         OBitmap := SelectObject(MemDC, NbresBMP);
         if d div 100 = 0 then BitBlt(PaintDC, x, 67, W, H, MemDC, 0, 0, srcCopy)
         else BitBlt(PaintDC, x, 67, W, H, MemDC, 0, 23 * (10 - d div 100), srcCopy);
         if (d div 100 = 0) and (d div 10 mod 10 = 0) then BitBlt(PaintDC, x + 13, 67, W, H, MemDC, 0, 0, srcCopy)
         else BitBlt(PaintDC, x + 13, 67, W, H, MemDC, 0, 23 * (10 - d div 10 mod 10), srcCopy);
         BitBlt(PaintDC, x + 26, 67, W, H, MemDC, 0, 23 * (10 - d mod 10), srcCopy);
         SelectObject(MemDc, OBitmap);
         DeleteDC(MemDC);
    end;

    procedure Croix;
    var NPen, OPen : HPen;
    begin
         TextOut(PaintDC, 130, 200, Statistique.Nom[1], StrLen(Statistique.Nom[1]));
         NPen := CreatePen(PS_Solid, 3, $000000FF);
         OPen := SelectObject(PaintDC, NPen);
         MoveTo(PaintDC, 100, 199);
         LineTo(PaintDC, 120, 219);
         MoveTo(PaintDC, 100, 219);
         LineTo(PaintDC, 120, 199);
         SelectObject(PaintDC, OPen);
         DeleteObject(NPen);
    end;

    procedure Rond;
    var NPen, OPen : HPen;
        OBrush : HBrush;
    begin
         TextOut(PaintDC, 130, 200, Statistique.Nom[2], StrLen(Statistique.Nom[2]));
         NPen := CreatePen(PS_Solid, 3, $00FF0000);
         OPen := SelectObject(PaintDC, NPen);
         OBrush := SelectObject(PaintDC, GetStockObject(Hollow_Brush));
         Ellipse(PaintDC, 100, 199, 120, 219);
         SelectObject(PaintDC, OBrush);
         SelectObject(PaintDC, OPen);
         DeleteObject(NPen);
    end;

begin
     TWindow.Paint(PaintDC, PaintInfo);
     commentaire;
     Titre;
     with statistique do
     begin
          TextOut(PaintDC, 167, 100, match, StrLen(match));
          victoire(NVictoires[1], ta_Right, 70, 120);
          victoire(NVictoires[2], ta_Left, 260, 120);
          pourcent(NVictoires[1], NParties, ta_Right, 70, 140);
          pourcent(NVictoires[2], NParties, ta_Left, 260, 140);
          pourcent(NVictoires[1], NVictoires[1] + NVictoires[2], ta_Right, 70, 160);
          pourcent(NVictoires[2], NVictoires[1] + NVictoires[2], ta_Left, 260, 160);
          TextOut(PaintDC, 150, 180, DGagnant, StrLen(DGagnant));
          case JoueurA of
               1 : Rond;
               2 : Croix
          else
              TextOut(PaintDC, 110, 200, 'Personne', 8);
          end;
          digital(temps, 78);
          digital(NParties, 288);
     end;
end;

procedure Scores.idOk(var Msg : TMessage); {Indique à la fenêtre appelant d'engager une nouvelle partie}
begin
     Redemarrer := True;
     SetFocus(HFen);           {La fenêtre appelant "Scores" et la fenêtre appelé par}
end;                                       {Scores" sont strictement les mêmes donc Statistiques = Stat}

destructor Scores.Done;
var cm_boucle : byte;
begin
     EnableMenuItem(Menu, cm_Scores, mf_ByCommand or mf_Enabled);
     EnableMenuItem(Menu, cm_Veille, mf_ByCommand or mf_Grayed);
     EnableMenuItem(Menu, cm_Stat_Zero, mf_ByCommand or mf_Grayed);
     for cm_boucle := cm_Arret to cm_Imprimante do EnableMenuItem(Menu, cm_boucle, mf_ByCommand or mf_Grayed);
     HScores := 0;
     DeleteObject(nbresBMP);
     if TitleBMP <> 0 then DeleteObject(TitleBMP);
     TWindow.Done;
end;

procedure Scores.cmStat_Zero(var Msg : TMessage);
begin
     Stat_Zero := True;
     SetFocus(HFen);
end;

procedure Scores.cmArret(var Msg : TMessage);
begin
     Fermeture1Fen := True;
     SetFocus(HFen);
end;

function Scores.titreBMP : HBitmap;
const periode = 10;
      rec : TRecT = (Left : 0; Top : 0; Right : bmWidth; Bottom : bmHeight);
var DC, MemDC : HDC;
    OBitmap, NBitmap : HBitmap;
    AlogFont : array[0..10] of TLogFont;

    OFont : HFont;
    boucle : byte;
    t : array[0..1] of Char;
    couleur : array[1..3] of byte;
    NFont, OldFont : HFont;

    OBrush, NBrush : HBrush;

    procedure Ecriture;
    var boucle2 : byte;
    begin
         FillChar(ALogFont, SizeOf(TLogFont), #0);
         with ALogFont[0] do
         begin
              lfHeight        := 42;
              lfWeight        := fw_Heavy;
              lfItalic        := 1;
              lfEscapement    := random(601) - 350;
              lfOutPrecision  := Out_Stroke_Precis;
              lfClipPrecision := Clip_Stroke_Precis;
              lfQuality       := Default_Quality;
              lfPitchAndFamily:= Variable_Pitch;
              StrCopy(lfFaceName, 'Arabia');
         end;
         for boucle2 := 1 to 10 do
         begin
              AlogFont[boucle2] := AlogFont[0];
              AlogFont[boucle2].lfEscapement := Random(601) - 300;
         end;
    end;


begin
     Ecriture;
     DC := GetDC(HWindow);
     MemDC := CreateCompatibleDC(DC);
     NBitmap := CreateCompatibleBitmap(DC, bmWidth, bmHeight);
     OBitmap := SelectObject(MemDC, NBitmap);

     NBrush := CreateSolidBrush(GetNearestColor(MemDC, $00CB2EB4));
     OBrush := SelectObject(MemDC, NBrush);
     FillRecT(MemDC, rec, NBrush);
     SelectOBject(MemDC, OBrush);
     DeleteObject(NBrush);


     SetBkMode(MemDC, Transparent);
     SetTextAlign(MemDC, ta_Center);
     t[1] := #0;
     for boucle := 0 to 10 do
     begin
          if En_tete[boucle] = ' ' then inc(boucle);
          NFont := CreateFontIndirect(ALogFont[boucle]);
          OFont := SelectObject(MemDC, NFont);
          SetTextColor(MemDC, $0);
          t[0] := En_tete[boucle];
          TextOut(MemDC, round(bmWidth / 12 * (boucle + 1)), 5, t, 1);
          repeat;
                 couleur[3] := random(255) + 1;
                 couleur[2] := random(255) + 1;
                 couleur[1] := random(255) + 1;
          until (GetNearestColor(MemDC, $00CB2EB4) <> GetNearestColor(MemDC, RGB(couleur[1], couleur[2], couleur[3])))
                 and (GetNearestColor(MemDC, RGB(couleur[1], couleur[2], couleur[3])) <> $0);
          SetTextColor(MemDC, RGB(couleur[1], couleur[2], couleur[3]));
          TextOut(MemDC, round(bmWidth / 12 * (boucle + 1)) + 2, 5, t, 1);
          SelectObject(MemDC, OFont);
          DeleteObject(NFont);
     end;

     SelectObject(MemDC, OBitmap);
     DeleteDC(MemDC);
     ReleaseDC(HWindow, DC);
     TitreBMP := NBitMap;
end;

begin
     with statistique do
     begin
          StrCopy(Match, 'Aucun match en cours.');
          NVictoires[1] := 0;
          NVictoires[2] := 0;
          NParties := 0;
          temps := 0;
          StrCopy(DGagnant, 'Personne');
          JoueurA := 0;
          HFen := 0;
          Redemarrer := False;
     end;
end.

{
  Mettre de la 3D dans le tableau d'affichage.

  Afficher le temps en heures, minutes et secondes.

  Ajouter le temps moyen par partie

}