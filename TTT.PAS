program tic_tac_toe;           {Début de programmation : 8 octobre 1993}

uses ODialogs, OWindows, WinTypes, WinProcs, Strings, UTic1, UTic2, UTic3;

{$R TTT.res}

const id_Menu = 100;
      id_Accs = 'AC';
      id_Propos = 'APD';
      cm_Exit2 = 108;
      cm_AF = 400;
      cm_FF = 401;
      cm_Propos = 999;
      id_Icon = 'TTT';
      id_FFDia = 'FF';
      id_AFDia = 'AF';
      posWindowMenu = 2;

{-----------------------------------------------------------------------------------------------}

type

TicTacToe = object(TApplication)
          procedure InitInstance; virtual;
          procedure InitMainWindow; virtual;
end;

PTTT = ^TTT;
TTT = object(TMDiWindow)

    Donnees : TDonnees;
    CursorHdl : HCursor;

    constructor Init(ATitle : PChar; AMenu : HMenu);
    function GetClassName : PChar; virtual;
    procedure GetWindowClass(var AWndClass : TWndClass); virtual;
    function prochaine(nbre : byte) : byte;
    procedure cmFF(var Msg : TMessage); virtual cm_First + cm_FF;
    procedure cmExit2(var Msg : TMessage); virtual cm_First + cm_Exit2;
    procedure cmAF(var Msg : TMessage); virtual cm_First + cm_AF;
    procedure cmPropos(var Msg : TMessage); virtual cm_First + cm_Propos;
    procedure cmScores(var Msg : TMessage); virtual cm_First + cm_Scores;
    procedure cmVeille(var Msg : TMessage); virtual cm_First + cm_Veille;
end;

{-----------------------------------------------------------------------------------------------}

procedure TicTacToe.InitInstance;
begin
     TApplication.InitInstance;
     HAccTable := LoadAccelerators(HInstance, PChar(id_Accs));
end;

procedure TicTacToe.InitMainWindow;
begin
     MainWindow := New(PTTT, Init(En_tete, LoadMenu(HInstance, PChar(id_Menu))));
end;

function TTT.GetClassName : PChar;
begin
     GetClassName := En_tete;
end;

procedure TTT.GetWindowClass(var AWndClass : TWndClass);
begin
     TWindow.GetWindowClass(AWndClass);
     AWndClass.HIcon := LoadIcon(HInstance, id_Icon);
end;

constructor TTT.Init(ATitle : PChar; AMenu : HMenu);
var boucle : byte;
begin
     TMDIWindow.Init(ATitle, AMenu);
     Menu := AMenu;
     ChildMenuPos := posWindowMenu;
     for boucle := 0 to 255 do
     begin
          Fenetre[1, boucle] := false;
          Fenetre[2, boucle] := false;
     end;
     FillChar(Donnees.Nom, SizeOf(Donnees.Nom), #0);
     Stat_Zero := False;
     CursorHdl := LOadCursor(0, idc_Wait);
end;

function TTT.prochaine(nbre : byte) : byte;        {1 = FF / 2 = AF}
begin
     with Donnees do
     begin
          NFen := 0;
          while (NFen <= 255) and Fenetre[nbre, NFen] do
                inc(NFen);
          Fenetre[nbre, NFen] := True;
          prochaine := NFen + 1;
     end;
end;

procedure TTT.cmAF(var Msg : TMessage);
var dim : TRecT;
    Titre : string[65];
begin
     Application^.ExecDialog(New(PAFDia, Init(@Self, PChar(id_AFDia), @donnees)));
     with donnees do
          if TJeu <> 0 then
          begin
               Titre := titre_Fen(Tjeu, prochaine(1), Nom);
               Application^.MakeWindow(New(PTTTJ, Init(@Self, @Titre[1], Donnees)));
          end;
end;

procedure TTT.CMFF(var Msg : TMessage);
var Titre : string[65];
begin
     Application^.ExecDialog(New(PFFDia, Init(@Self, PChar(id_FFDia), @Donnees)));
     with donnees do
          if TJeu = 5 then
          begin
               Titre := titre_Fen(Tjeu, prochaine(2), Nom);
               Application^.MakeWindow(New(PTTTJ, Init(@Self, @Titre[1], Donnees)));
          end;
end;

procedure TTT.cmExit2(var Msg : TMessage);
begin
     MessageBox(HWindow, 'Alessandro SALSETTI vous remercie d''avoir utilisé sa nouvelle création.'+
     #13+
     'Mais n''oubliez pas que Tic Tac Toe attend avec impatience sa prochaine occasion de vous plumer'+
     ' et de vous mettre les nerfs en boule.', 'Au revoir et merci...', mb_Ok or mb_IconHand);
     CloseWindow;
end;

procedure TTT.cmPropos(var Msg : TMessage);
begin
     Application^.ExecDialog(New(PDialog, Init(@Self, PChar(id_Propos))));
end;

procedure TTT.cmScores(var Msg : TMessage);
var OCursor : HCursor;
begin
     OCursor := SetCursor(CursorHdl);
     Application^.MakeWindow(New(PScores, Init(@Self, 'Statistiques & Scores')));
     SetCursor(OCursor);
end;

procedure TTT.cmVeille(var Msg : TMessage);
begin
     SetFocus(HScores);
end;


{-----------------------------------------------------------------------------------------------}

var Jeu : TicTacToe;

begin
     Randomize;
     Jeu.Init(En_tete);
     Jeu.Run;
     Jeu.Done;
end.                           {Fin de programmation : 9 janvier 1993}

{
        Première adaptation sur Turbo Pascal pour DOS : 5 - 7 octobre 1993
        par : SALSETTI Alessandro.

        Implémenter une barre de boutons pour faire plus pro.

        Ce programme restera probablement à tout jamais en chantier puisqu'il ne reste
        plus que quelques commandes (non vitales) du menu à mettre en fonction et
        à améliorer sérieusement la planche de jeux et l'affichage des statistiques (3D).
}
