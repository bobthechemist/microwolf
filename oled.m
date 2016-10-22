BeginPackage["oled`"]

oledSetup::usage="Initialize display, input pins and (eventually) python process."
oledImage::usage="Send properly formatted image to the display"
oledText::usage="Sends a line of text to the display"
oledPlot::usage="Plot directed to the oled"
oledCleanup::usage="Attempts to kill processes and tasks"
oledLoop::usage="The main program loop"
oledRun::usage="Runs the three parts of the oled program"
bmpRead::usage="Returns association with temp and pressure"

Begin["`Private`"]

(* Adjust these variables as needed *)
$welcome = "\[Mu] \[Wolf] 8 \[Sum] \[Pi]";
$oleddriver = "sudo /home/pi/oled/oled.py";
$bmpdriver = "/home/pi/oled/readbmp180.py";
$tempfile = "/tmp/oledwolfram.png";
$datafile = "/tmp/oleddata";
$gpio = {14, 15, 18};
$flags = ConstantArray[1,Length@$gpio]; 
$readpins = True;
$shellprocess = Null;
$task = Null;
$datatask = Null;

(* Read gpio pins and store in $flags *)

readpins[OptionsPattern[{force->False}]] := Module[{temp},
  temp = $flags;
  $readpins = True;
  If[Or[OptionValue[force],$readpins], (
    WriteLine[$shellprocess, "gpio -g read " <> ToString@#] & /@ $gpio;
    Pause[0.1];
    $flags = ToExpression/@StringSplit@ReadString[$shellprocess, EndOfBuffer];
    $readpins = If[$flags == temp, True, False];
    );];
]


oledSetup[] := Module[{validpins, tsk},
  (* Display welcome message *)
  oledText[$welcome, Large];
  Pause[1];

  (* Use WiringPi gpio utility to set GPIO pins as input with pull-up resistors *)
  validpins = Cases[$gpio, x_ /; MemberQ[{14,15,18},x] ]; (* Example GPIO pin sanity check *)

  oledText["Starting shell process."];
  (* Start a system shell *)
  $shellprocess = StartProcess[$SystemShell];
  
  WriteLine[$shellprocess, "gpio -g mode " <>  ToString@# <> " in"] & /@ validpins;
  WriteLine[$shellprocess, "gpio -g mode " <>  ToString@# <> " up"] & /@ validpins;
  ReadString[$shellprocess, EndOfBuffer];

  oledText["Starting datalog task"];
  Put[{Now, bmpRead[]}, $datafile];
  $datatask = RunScheduledTask[PutAppend[{Now,bmpRead[]},$datafile],30];

  oledText["Starting interrupt task"]; 
  $task = RunScheduledTask[readpins[], 0.5];
  (* First interation of scheduled task does not capture pins.  Give it a few seconds then force another read *)
  Pause[2];
  $readpins = True;
  Pause[2];
  $readpins = True;


  oledText["Ready to help"];
]

oledImage[img_] := Module[{},
  Export[$tempfile, img];
  Run[$oleddriver <> " --image " <> $tempfile ];
]

oledText[str_String, style_:Smaller] := Module[{img},
  img = Graphics[{White, Text[Style[str,ReleaseHold@style],{1,0}]}, Background -> Black, ImageSize -> {128, 32}];
  oledImage@img;
]

oledCleanup[] := Module[{},
  RemoveScheduledTask[$task];
  $task = Null;
  RemoveScheduledTask[$datatask];
  $datatask = Null;
  KillProcess[$shellprocess];
  $shellprocess = Null;
  oledText["Goodbye !"];
]

oledRun[] := Module[{},
  oledSetup[];
  oledLoop[];
  oledCleanup[];
]


oledLoop[] := Module[{iter},
  iter = 0;
  oledText["Starting loop"];
  While[iter < 5,
    If[Total@$flags < 3,
      ( 
        If[$flags[[1]]==0,
          oledText["Temp: " <> ToString@bmpRead[]["Temperature"]]];
        If[$flags[[2]]==0,
          oledText["Pressure: " <> ToString@bmpRead[]["Pressure"]]];
        If[$flags[[3]]==0,
          Break];
        iter += 1;
        $readpins = True;
      ),
      Pause[1]
    ];
  ]
]


oledPlot[fn_, {var_, varmin_, varmax_}, opts : OptionsPattern[Plot]]:= Module[{img, ticks},
  img = Plot[fn,{var,varmin,varmax}, AspectRatio->0.25,ImageSize->{128,32},
    PlotStyle->{White,Thickness[0.01]}, FrameStyle->White, Background->Black,
    BaseStyle->{White,FontFamily->"FreeSans",FontSize->7},
    Axes->False,Frame->{True,True,False,False}, 
    FrameTicks->{Automatic, (IntegerPart/@{#1, #2})&}];
  oledImage@img;
]

bmpRead[] := Module[{a,t},
  t = RunProcess[{"sudo",$bmpdriver}]["StandardOutput"];
  t = ToExpression@StringSplit[t, ", "];
  Association[{"Temperature"->First@t,"Pressure"->Last@t}]
]
End[]
EndPackage[]
