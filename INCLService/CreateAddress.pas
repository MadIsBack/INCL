unit CreateAddress;

interface

procedure InitAddr;

implementation

uses DBMain, SysUtils;

procedure InitAddr;
begin
  MerkerSchichtwechsel := 'M2.1';
  MerkerRoteLampe := 'A28.6';
  //Produzierte Artikel
  //StueckGesamt

  //Reset
  AuftragReset[1].Produziert := 'DB16,X10.3,1';
  AuftragReset[1].Geprueft := 'DB18,X6.2,1';
  AuftragReset[1].Verpackt := 'DB20,X266.2';

  AuftragReset[2].Produziert := 'DB16,X30.3,1';
  AuftragReset[2].Geprueft := 'DB18,X26.2,1';
  AuftragReset[2].Verpackt := 'DB20,X286.2';

  AuftragReset[3].Produziert := 'DB16,X50.3,1';
  AuftragReset[3].Geprueft := 'DB18,X46.2,1';
  AuftragReset[3].Verpackt := 'DB20,X306.2';

  AuftragReset[4].Produziert := 'DB16,X70.3,1';
  AuftragReset[4].Geprueft := 'DB18,X66.2,1';
  AuftragReset[4].Verpackt := 'DB20,X326.2';

  AuftragReset[5].Produziert := 'DB16,X90.3,1';
  AuftragReset[5].Geprueft := 'DB18,X86.2,1';
  AuftragReset[5].Verpackt := 'DB20,X346.2';

  AuftragReset[6].Produziert := 'DB16,X110.3,1';
  AuftragReset[6].Geprueft := 'DB18,X106.2,1';
  AuftragReset[6].Verpackt := 'DB20,X366.2';

  AuftragReset[7].Produziert := 'DB16,X130.3,1';
  AuftragReset[7].Geprueft := 'DB18,X126.2,1';
  AuftragReset[7].Verpackt := 'DB20,X386.2';

  AuftragReset[8].Produziert := 'DB16,X150.3,1';
  AuftragReset[8].Geprueft := 'DB18,X146.2,1';
  AuftragReset[8].Verpackt := 'DB20,X406.2';

  AuftragReset[9].Produziert := 'DB16,X170.3,1';
  AuftragReset[9].Geprueft := 'DB18,X166.2,1';
  AuftragReset[9].Verpackt := 'DB20,X426.2';

  AuftragReset[10].Produziert := 'DB16,X190.3,1';
  AuftragReset[10].Geprueft := 'DB18,X186.2,1';
  AuftragReset[10].Verpackt := 'DB20,X446.2';

  AuftragReset[11].Produziert := 'DB16,X210.3,1';
  AuftragReset[11].Geprueft := 'DB18,X206.2,1';
  AuftragReset[11].Verpackt := 'DB20,X466.2';

  AuftragReset[12].Produziert := 'DB16,X230.3,1';
  AuftragReset[12].Geprueft := 'DB18,X226.2,1';
  AuftragReset[12].Verpackt := 'DB20,X486.2';

  AuftragReset[13].Produziert := 'DB16,X250.3,1';
  AuftragReset[13].Geprueft := 'DB18,X246.2,1';
  AuftragReset[13].Verpackt := 'DB20,X506.2';

  AuftragReset[14].Produziert := 'DB16,X270.3,1';
  AuftragReset[14].Geprueft := 'DB18,X266.2,1';
  AuftragReset[14].Verpackt := 'DB20,X526.2';

  AuftragReset[15].Produziert := 'DB16,X290.3,1';
  AuftragReset[15].Geprueft := 'DB18,X286.2,1';
  AuftragReset[15].Verpackt := 'DB20,X546.2';

  AuftragReset[16].Produziert := 'DB16,X310.3,1';
  AuftragReset[16].Geprueft := 'DB18,X306.2,1';
  AuftragReset[16].Verpackt := 'DB20,X566.2';

  AuftragReset[17].Produziert := 'DB16,X330.3,1';
  AuftragReset[17].Geprueft := 'DB18,X326.2,1';
  AuftragReset[17].Verpackt := 'DB20,X586.2';

  AuftragReset[18].Produziert := 'DB16,X350.3,1';
  AuftragReset[18].Geprueft := 'DB18,X346.2,1';
  AuftragReset[18].Verpackt := 'DB20,X606.2';

  AuftragReset[19].Produziert := 'DB16,X370.3,1';
  AuftragReset[19].Geprueft := 'DB18,X366.2,1';
  AuftragReset[19].Verpackt := 'DB20,X626.2';

  AuftragReset[20].Produziert := 'DB16,X390.3,1';
  AuftragReset[20].Geprueft := 'DB18,X386.2,1';
  AuftragReset[20].Verpackt := 'DB20,X646.2';

  AuftragReset[21].Produziert := 'DB16,X410.3,1';
  AuftragReset[21].Geprueft := 'DB18,X406.2,1';
  AuftragReset[21].Verpackt := 'DB20,X666.2';

  AuftragReset[22].Produziert := 'DB16,X430.3,1';
  AuftragReset[22].Geprueft := 'DB18,X426.2,1';
  AuftragReset[22].Verpackt := 'DB20,X686.2';

  AuftragReset[23].Produziert := 'DB16,X450.3,1';
  AuftragReset[23].Geprueft := 'DB18,X446.2,1';
  AuftragReset[23].Verpackt := 'DB20,X706.2';

  AuftragReset[24].Produziert := 'DB16,X470.3,1';
  AuftragReset[24].Geprueft := 'DB18,X466.2,1';
  AuftragReset[24].Verpackt := 'DB20,X726.2';

  AuftragReset[25].Produziert := 'DB16,X490.3,1';
  AuftragReset[25].Geprueft := 'DB18,X486.2,1';
  AuftragReset[25].Verpackt := 'DB20,X746.2';

  AuftragReset[26].Produziert := 'DB16,X510.3,1';
  AuftragReset[26].Geprueft := 'DB18,X506.2,1';
  AuftragReset[26].Verpackt := 'DB20,X766.2';

  AuftragReset[27].Produziert := 'DB16,X530.3,1';
  AuftragReset[27].Geprueft := 'DB18,X526.2,1';
  AuftragReset[27].Verpackt := 'DB20,X786.2';

  AuftragReset[28].Produziert := 'DB16,X550.3,1';
  AuftragReset[28].Geprueft := 'DB18,X546.2,1';
  AuftragReset[28].Verpackt := 'DB20,X806.2';

  AuftragReset[29].Produziert := 'DB16,X570.3,1';
  AuftragReset[29].Geprueft := 'DB18,X566.2,1';
  AuftragReset[29].Verpackt := 'DB20,X826.2';

  AuftragReset[30].Produziert := 'DB16,X590.3,1';
  AuftragReset[30].Geprueft := 'DB18,X586.2,1';
  AuftragReset[30].Verpackt := 'DB20,X846.2';

  AuftragReset[31].Produziert := 'DB16,X610.3,1';
  AuftragReset[31].Geprueft := 'DB18,X606.2,1';
  AuftragReset[31].Verpackt := 'DB20,X866.2';

  AuftragReset[32].Produziert := 'DB16,X630.3,1';
  AuftragReset[32].Geprueft := 'DB18,X626.2,1';
  AuftragReset[32].Verpackt := 'DB20,X886.2';

end;

end.

