Unit UTic1;

Interface

uses OWindows, WinTypes, Strings, ODialogs;

type
    TNom20 = array[0..20] of Char;
    TNom = array[1..2] of TNom20;
    PTDonnees = ^TDonnees;
    TDonnees = record Nom : TNom;
                      TJeu : byte;
                      NFen : byte;
               end;

    PFFDia = ^FFDia;
    FFDia = object(TDialog)
          DataPointer : PTDonnees;
          constructor Init(AParent: PWindowsObject; AName: PChar; N : PTDonnees);
          procedure SetUpWindow; virtual;
          procedure Ok(var Msg : TMessage); virtual id_First + id_Ok;
    end;
    PAFDia = ^AFDia;
    AFDia = object(TDialog)
          DataPointer : PTDonnees;
          constructor Init(AParent: PWindowsObject; AName: PChar; N : PTDonnees);
          procedure SetUpWindow; virtual;
          procedure OK(var Msg : TMessage); virtual id_First + id_OK;
    end;

{-----------------------------------------------------------------------------------------------}

Implementation

{$R Utic1.res}

const id_Nom = 300;
      max = 20;
      id_pre_coup = 301;
      id_Aleatoire = 303;

constructor FFDia.Init(AParent: PWindowsObject; AName: PChar; N : PTDonnees);
begin
     TDialog.Init(AParent, AName);
     DataPointer := N;
     DataPointer^.TJeu := 0;
end;

procedure FFDia.SetUpWindow;
var boucle : byte;
begin
     TDialog.SetUpWindow;
     SendDlgItemMsg(id_Nom, em_LimitText, Max, 0);
     SendDlgItemMsg(id_Nom, wm_SetText, 0, LongInt(@DataPointer^.Nom[1]));
     SendDlgItemMsg(id_Nom + 1, em_LimitText, Max, 0);
     SendDlgItemMsg(id_Nom + 1, wm_SetText, 0, LongInt(@DataPointer^.Nom[2]));
end;

procedure FFDia.Ok(var Msg : TMessage);
var boucle : byte;
begin
     for boucle := 1 to 2 do 
         SendDlgItemMsg(id_Nom + boucle - 1, wm_GetText, max + 1, LongInt(@DataPointer^.Nom[boucle]));
     TDialog.Ok(Msg);
     DataPointer^.TJeu := 5;
end;

constructor AFDia.Init(AParent: PWindowsObject; AName: PChar; N : PTDonnees);
begin
     TDialog.Init(AParent, AName);
     DataPointer := N;
     DataPointer^.TJeu := 0;
end;

procedure AFDia.SetUpWindow;
begin
     TDialog.SetUpWindow;
     SendDlgItemMsg(id_Nom, em_LimitText, Max, 0);
     if StrComp(@DataPointer^.Nom[1], 'Destroyer') = 0 then
        SendDlgItemMsg(id_Nom, wm_SetText, 0, LongInt(@DataPointer^.Nom[1]))
     else
        SendDlgItemMsg(id_Nom, wm_SetText, 0, LongInt(@DataPointer^.Nom[2]));
     SendDlgItemMsg(id_Pre_Coup, bm_SetCheck, 1, 0);
     SendDlgItemMsg(id_Aleatoire + 1, bm_SetCheck, 1, 0);
end;

procedure AFDia.Ok(var Msg : TMessage);
begin
     with DataPointer^ do
     begin
          SendDlgItemMsg(id_Nom, wm_GetText, max + 1, LongInt(@Nom[1]));
          if SendDlgItemMsg(id_Pre_Coup, bm_GetCheck, 0, 0) = 0 then
          begin
               TJeu := 1;
               SendDlgItemMsg(id_Nom, wm_GetText, max + 1, LongInt(@Nom[1]));
               StrCopy(@Nom[2], 'Destroyer');
          end
          else
          begin
               TJeu := 2;
               SendDlgItemMsg(id_Nom, wm_GetText, max + 1, LongInt(@Nom[2]));
               StrCopy(@Nom[1], 'Destroyer');
          end;
          if SendDlgItemMsg(id_Aleatoire, bm_GetCheck, 0, 0) = 0 then inc(TJeu, 2);
     end; 
     TDialog.Ok(Msg);
end;

end.

{
  TJeu = 1 : Jeu semi-aléatoire, le joueur commence la partie;
  TJeu = 2 : Jeu semi-aléatoire, Destroyer commence la partie;
  TJeu = 3 : Jeu aléatoire, le joueur commence la partie;
  TJeu = 4 : Jeu aléatoire, Destroyer commence la partie;
  TJeu = 5 : Des joueurs.

  Améliorer la présentation de la fenêtre "A propos de..."
}