unit tests.rtti;

{$ifdef fpc}
{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$endif}

interface

uses
{$IFDEF FPC}
  fpcunit,testregistry, testutils,
{$ELSE FPC}
  TestFramework,
{$ENDIF FPC}
  Classes, SysUtils, typinfo,
  Rtti;

type

  { TTestCase1 }

  TTestCase1= class(TTestCase)
  published
    //procedure GetTypes;
    procedure GetTypeInteger;
    procedure GetTypePointer;
    procedure GetClassProperties;

    procedure GetClassPropertiesValue;

    procedure TestTRttiTypeProperties;
    procedure TestPropGetValueString;
    procedure TestPropGetValueInteger;
    procedure TestPropGetValueBoolean;
    procedure TestPropGetValueShortString;
    procedure TestPropGetValueProcString;
    procedure TestPropGetValueProcInteger;
    procedure TestPropGetValueProcBoolean;
    procedure TestPropGetValueProcShortString;

    procedure TestPropSetValueString;
    procedure TestPropSetValueInteger;
    procedure TestPropSetValueBoolean;
    procedure TestPropSetValueShortString;

    procedure TestGetValueStringCastError;
    procedure TestGetIsReadable;
    procedure TestIsWritable;

    procedure TestMakeNil;
    procedure TestMakeObject;
    procedure TestMakeArrayDynamic;
    procedure TestMakeArrayStatic;

    procedure TestDataSize;
    procedure TestDataSizeEmpty;
    procedure TestReferenceRawData;
    procedure TestReferenceRawDataEmpty;

    procedure TestIsManaged;
  end;

implementation

type

  {$M+}
  TGetClassProperties = class
  private
    FPubPropRO: integer;
    FPubPropRW: integer;
  published
    property PubPropRO: integer read FPubPropRO;
    property PubPropRW: integer read FPubPropRW write FPubPropRW;
    property PubPropSetRO: integer read FPubPropRO;
    property PubPropSetRW: integer read FPubPropRW write FPubPropRW;
  end;

  TGetClassPropertiesSub = class(TGetClassProperties)

  end;
  {$M-}

  { TTestValueClass }

  {$M+}
  TTestValueClass = class
  private
    FAInteger: integer;
    FAString: string;
    FABoolean: boolean;
    FAShortString: ShortString;
    function GetAInteger: integer;
    function GetAString: string;
    function GetABoolean: boolean;
    function GetAShortString: ShortString;
    procedure SetWriteOnly(AValue: integer);
  published
    property AInteger: Integer read FAInteger write FAInteger;
    property AString: string read FAString write FAString;
    property ABoolean: boolean read FABoolean write FABoolean;
    property AShortString: ShortString read FAShortString write FAShortString;
    property AGetInteger: Integer read GetAInteger;
    property AGetString: string read GetAString;
    property AGetBoolean: boolean read GetABoolean;
    property AGetShortString: ShortString read GetAShortString;
    property AWriteOnly: integer write SetWriteOnly;
  end;
  {$M-}

  TManagedRec = record
    s: string;
  end;

{$ifdef fpc}
  TManagedRecOp = record
    class operator AddRef(var a: TManagedRecOp);
  end;
{$endif}

  TNonManagedRec = record
    i: Integer;
  end;

  TManagedObj = object
    i: IInterface;
  end;

  TNonManagedObj = object
    d: double;
  end;

  TTestEnum = (te1, te2, te3, te4, te5);
  TTestSet = set of TTestEnum;

  TTestProc = procedure;
  TTestMethod = procedure of object;
  TTestHelper = class helper for TObject
  end;

  TArrayOfString = array[0..0] of string;
  TArrayOfManagedRec = array[0..0] of TManagedRec;
  TArrayOfNonManagedRec = array[0..0] of TNonManagedRec;
  TArrayOfByte = array[0..0] of byte;

  TArrayOfLongintDyn = array of LongInt;
  TArrayOfLongintStatic = array[0..3] of LongInt;

  TTestRecord = record
    Value1: LongInt;
    Value2: String;
  end;
  PTestRecord = ^TTestRecord;

{$ifdef fpc}
{$PUSH}
{$INTERFACES CORBA}

  ICORBATest = interface
  end;

{$POP}
{$endif}

{$ifdef fpc}
class operator TManagedRecOp.AddRef(var  a: TManagedRecOp);
begin
end;
{$endif}

{ TTestValueClass }

function TTestValueClass.GetAInteger: integer;
begin
  result := FAInteger;
end;

function TTestValueClass.GetAString: string;
begin
  result := FAString;
end;

function TTestValueClass.GetABoolean: boolean;
begin
  result := FABoolean;
end;

function TTestValueClass.GetAShortString: ShortString;
begin
  Result := FAShortString;
end;

procedure TTestValueClass.SetWriteOnly(AValue: integer);
begin
  // Do nothing
end;

{ Note: GetTypes currently only returns those types that had been acquired using
        GetType, so GetTypes itself can't be really tested currently }
(*procedure TTestCase1.GetTypes;
var
  LContext: TRttiContext;
  LType: TRttiType;
  IsTestCaseClassFound: boolean;
begin
  LContext := TRttiContext.Create;

  { Enumerate all types declared in the application }
  for LType in LContext.GetTypes() do
    begin
    if LType.Name='TTestCase1' then
      IsTestCaseClassFound:=true;
    end;
  LContext.Free;
  CheckTrue(IsTestCaseClassFound, 'RTTI information does not contain class of testcase.');
end;*)

procedure TTestCase1.TestGetValueStringCastError;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AValue: TValue;
  i: integer;
  HadException: boolean;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AString := '12';
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      AValue := ARttiType.GetProperty('astring').GetValue(ATestClass);
      HadException := false;
      try
        i := AValue.AsInteger;
      except
        on E: Exception do
          if E.ClassType=EInvalidCast then
            HadException := true;
      end;
      Check(HadException, 'No or invalid exception on invalid cast');
    finally
      AtestClass.Free;
    end;
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestMakeNil;
var
  value: TValue;
begin
  TValue.Make(Nil, Nil, value);
  CheckTrue(value.Kind = tkUnknown);
  CheckTrue(value.IsEmpty);
  CheckTrue(value.IsObject);
  CheckTrue(value.IsClass);
  CheckTrue(value.IsOrdinal);
  CheckFalse(value.IsArray);
  CheckTrue(value.AsObject = Nil);
  CheckTrue(value.AsClass = Nil);
  CheckTrue(value.AsInterface = Nil);
  CheckEquals(0, value.AsOrdinal);

  TValue.Make(Nil, TypeInfo(TObject), value);
  CheckTrue(value.IsEmpty);
  CheckTrue(value.IsObject);
  CheckTrue(value.IsClass);
  CheckTrue(value.IsOrdinal);
  CheckFalse(value.IsArray);
  CheckTrue(value.AsObject=Nil);
  CheckTrue(value.AsClass=Nil);
  CheckTrue(value.AsInterface=Nil);
  CheckEquals(0, value.AsOrdinal);

  TValue.Make(Nil, TypeInfo(TClass), value);
  CheckTrue(value.IsEmpty);
  CheckTrue(value.IsClass);
  CheckTrue(value.IsOrdinal);
  CheckFalse(value.IsArray);
  CheckTrue(value.AsObject=Nil);
  CheckTrue(value.AsClass=Nil);
  CheckTrue(value.AsInterface=Nil);
  CheckEquals(0, value.AsOrdinal);

  TValue.Make(Nil, TypeInfo(LongInt), value);
  CheckTrue(value.IsOrdinal);
  CheckFalse(value.IsEmpty);
  CheckFalse(value.IsClass);
  CheckFalse(value.IsObject);
  CheckFalse(value.IsArray);
  CheckEquals(0, value.AsOrdinal);
  CheckEquals(0, value.AsInteger);
  CheckEquals(0, value.AsInt64);
  CheckEquals(0, value.AsUInt64);

  TValue.Make(Nil, TypeInfo(String), value);
  CheckFalse(value.IsEmpty);
  CheckFalse(value.IsObject);
  CheckFalse(value.IsClass);
  CheckFalse(value.IsArray);
  CheckEquals('', value.AsString);
end;

procedure TTestCase1.TestMakeObject;
var
  AValue: TValue;
  ATestClass: TTestValueClass;
begin
  ATestClass := TTestValueClass.Create;
  ATestClass.AInteger := 54329;
  TValue.Make(@ATestClass, TypeInfo(TTestValueClass),AValue);
  CheckEquals(AValue.IsClass, False);
  CheckEquals(AValue.IsObject, True);
  Check(AValue.AsObject=ATestClass);
  CheckEquals(TTestValueClass(AValue.AsObject).AInteger, 54329);
  ATestClass.Free;
end;

procedure TTestCase1.TestMakeArrayDynamic;
var
  arr: TArrayOfLongintDyn;
  value: TValue;
begin
  SetLength(arr, 2);
  arr[0] := 42;
  arr[1] := 21;
  TValue.Make(@arr, TypeInfo(TArrayOfLongintDyn), value);
  CheckEquals(value.IsArray, True);
  CheckEquals(value.IsObject, False);
  CheckEquals(value.IsOrdinal, False);
  CheckEquals(value.IsClass, False);
  CheckEquals(value.GetArrayLength, 2);
  CheckEquals(value.GetArrayElement(0).AsInteger, 42);
  CheckEquals(value.GetArrayElement(1).AsInteger, 21);
  value.SetArrayElement(0, 84);
  CheckEquals(arr[0], 84);
end;

procedure TTestCase1.TestMakeArrayStatic;
type
  TArrStat = array[0..1] of LongInt;
  TArrStat2D = array[0..1, 0..1] of LongInt;
var
  arr: TArrStat;
  arr2D: TArrStat2D;
  value: TValue;
begin
  arr[0] := 42;
  arr[1] := 21;
  TValue.Make(@arr, TypeInfo(TArrStat), value);
  CheckEquals(value.IsArray, True);
  CheckEquals(value.IsObject, False);
  CheckEquals(value.IsOrdinal, False);
  CheckEquals(value.IsClass, False);
  CheckEquals(value.GetArrayLength, 2);
  CheckEquals(value.GetArrayElement(0).AsInteger, 42);
  CheckEquals(value.GetArrayElement(1).AsInteger, 21);
  value.SetArrayElement(0, 84);
  { since this is a static array the original array isn't touched! }
  CheckEquals(arr[0], 42);

  arr2D[0, 0] := 42;
  arr2D[0, 1] := 21;
  arr2D[1, 0] := 84;
  arr2D[1, 1] := 63;

  TValue.Make(@arr2D, TypeInfo(TArrStat2D), value);
  CheckEquals(value.IsArray, True);
  CheckEquals(value.GetArrayLength, 4);
  CheckEquals(value.GetArrayElement(0).AsInteger, 42);
  CheckEquals(value.GetArrayElement(1).AsInteger, 21);
  CheckEquals(value.GetArrayElement(2).AsInteger, 84);
  CheckEquals(value.GetArrayElement(3).AsInteger, 63);
end;

procedure TTestCase1.TestGetIsReadable;
var
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
begin
  c := TRttiContext.Create;
  try
    ARttiType := c.GetType(TTestValueClass);
    AProperty := ARttiType.GetProperty('aBoolean');
    CheckEquals(AProperty.IsReadable, true);
    AProperty := ARttiType.GetProperty('aGetBoolean');
    CheckEquals(AProperty.IsReadable, true);
    AProperty := ARttiType.GetProperty('aWriteOnly');
    CheckEquals(AProperty.IsReadable, False);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestIsWritable;
var
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
begin
  c := TRttiContext.Create;
  try
    ARttiType := c.GetType(TTestValueClass);
    AProperty := ARttiType.GetProperty('aBoolean');
    CheckEquals(AProperty.IsWritable, true);
    AProperty := ARttiType.GetProperty('aGetBoolean');
    CheckEquals(AProperty.IsWritable, false);
    AProperty := ARttiType.GetProperty('aWriteOnly');
    CheckEquals(AProperty.IsWritable, True);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueBoolean;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.ABoolean := true;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('aBoolean');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals(true,AValue.AsBoolean);
      ATestClass.ABoolean := false;
      CheckEquals(true, AValue.AsBoolean);
      CheckEquals('True', AValue.ToString);
      CheckEquals(True, AValue.IsOrdinal);
      CheckEquals(1, AValue.AsOrdinal);
    finally
      AtestClass.Free;
    end;
      CheckEquals(True,AValue.AsBoolean);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueShortString;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AShortString := 'Hello World';
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('aShortString');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals('Hello World',AValue.AsString);
      ATestClass.AShortString := 'Foobar';
      CheckEquals('Hello World', AValue.AsString);
      CheckEquals(False, AValue.IsOrdinal);
      CheckEquals(False, AValue.IsObject);
      CheckEquals(False, AValue.IsArray);
      CheckEquals(False, AValue.IsClass);
    finally
      AtestClass.Free;
    end;
    CheckEquals('Hello World',AValue.AsString);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueInteger;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AInteger := 472349;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('ainteger');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals(472349,AValue.AsInteger);
      ATestClass.AInteger := 12;
      CheckEquals(472349, AValue.AsInteger);
      CheckEquals('472349', AValue.ToString);
      CheckEquals(True, AValue.IsOrdinal);
    finally
      AtestClass.Free;
    end;
      CheckEquals(472349,AValue.AsInteger);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueString;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
  i: int64;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AString := 'Hello World';
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('astring');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals('Hello World',AValue.AsString);
      ATestClass.AString := 'Goodbye World';
      CheckEquals('Hello World',AValue.AsString);
      CheckEquals('Hello World',AValue.ToString);
      Check(TypeInfo(string)=AValue.TypeInfo);
      Check(AValue.TypeData=GetTypeData(AValue.TypeInfo));
      Check(AValue.IsEmpty=false);
      Check(AValue.IsObject=false);
      Check(AValue.IsClass=false);
      CheckEquals(AValue.IsOrdinal, false);
      CheckEquals(AValue.TryAsOrdinal(i), false);
      CheckEquals(AValue.IsType(TypeInfo(string)), true);
      CheckEquals(AValue.IsType(TypeInfo(integer)), false);
      CheckEquals(AValue.IsArray, false);
    finally
      AtestClass.Free;
    end;
    CheckEquals('Hello World',AValue.AsString);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueProcBoolean;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.ABoolean := true;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('aGetBoolean');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals(true,AValue.AsBoolean);
    finally
      AtestClass.Free;
    end;
      CheckEquals(True,AValue.AsBoolean);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueProcShortString;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AShortString := 'Hello World';
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('aGetShortString');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals('Hello World',AValue.AsString);
    finally
      AtestClass.Free;
    end;
    CheckEquals('Hello World',AValue.AsString);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropSetValueString;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
  s: string;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      AProperty := ARttiType.GetProperty('astring');

      s := 'ipse lorem or something like that';
      TValue.Make(@s, TypeInfo(string), AValue);
      AProperty.SetValue(ATestClass, AValue);
      CheckEquals(ATestClass.AString, s);
      s := 'Another string';
      CheckEquals(ATestClass.AString, 'ipse lorem or something like that');
    finally
      AtestClass.Free;
    end;
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropSetValueInteger;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
  i: integer;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      AProperty := ARttiType.GetProperty('aInteger');

      i := -43573;
      TValue.Make(@i, TypeInfo(Integer), AValue);
      AProperty.SetValue(ATestClass, AValue);
      CheckEquals(ATestClass.AInteger, i);
      i := 1;
      CheckEquals(ATestClass.AInteger, -43573);
    finally
      AtestClass.Free;
    end;
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropSetValueBoolean;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
  b: boolean;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      AProperty := ARttiType.GetProperty('aboolean');

      b := true;
      TValue.Make(@b, TypeInfo(Boolean), AValue);
      AProperty.SetValue(ATestClass, AValue);
      CheckEquals(ATestClass.ABoolean, b);
      b := false;
      CheckEquals(ATestClass.ABoolean, true);
      TValue.Make(@b, TypeInfo(Boolean), AValue);
      AProperty.SetValue(ATestClass, AValue);
      CheckEquals(ATestClass.ABoolean, false);
    finally
      AtestClass.Free;
    end;
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropSetValueShortString;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
  s: string;
  ss: ShortString;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      AProperty := ARttiType.GetProperty('aShortString');

      s := 'ipse lorem or something like that';
      TValue.Make(@s, TypeInfo(String), AValue);
      AProperty.SetValue(ATestClass, AValue);
      CheckEquals(ATestClass.AShortString, s);
      s := 'Another string';
      CheckEquals(ATestClass.AShortString, 'ipse lorem or something like that');

      ss := 'Hello World';
      TValue.Make(@ss, TypeInfo(ShortString), AValue);
      AProperty.SetValue(ATestClass, AValue);
      CheckEquals(ATestClass.AShortString, ss);
      ss := 'Foobar';
      CheckEquals(ATestClass.AShortString, 'Hello World');
    finally
      AtestClass.Free;
    end;
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueProcInteger;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AInteger := 472349;
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('agetinteger');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals(472349,AValue.AsInteger);
    finally
      AtestClass.Free;
    end;
      CheckEquals(472349,AValue.AsInteger);
  finally
    c.Free;
  end;
end;

procedure TTestCase1.TestPropGetValueProcString;
var
  ATestClass : TTestValueClass;
  c: TRttiContext;
  ARttiType: TRttiType;
  AProperty: TRttiProperty;
  AValue: TValue;
begin
  c := TRttiContext.Create;
  try
    ATestClass := TTestValueClass.Create;
    ATestClass.AString := 'Hello World';
    try
      ARttiType := c.GetType(ATestClass.ClassInfo);
      Check(assigned(ARttiType));
      AProperty := ARttiType.GetProperty('agetstring');
      AValue := AProperty.GetValue(ATestClass);
      CheckEquals('Hello World',AValue.AsString);
    finally
      AtestClass.Free;
    end;
    CheckEquals('Hello World',AValue.AsString);
  finally
    c.Free;
  end;
end;


procedure TTestCase1.TestTRttiTypeProperties;
var
  c: TRttiContext;
  ARttiType: TRttiType;

begin
  c := TRttiContext.Create;
  try
    ARttiType := c.GetType(TTestValueClass);
    Check(assigned(ARttiType));
    CheckEquals(ARttiType.Name,'TTestValueClass');
    Check(ARttiType.TypeKind=tkClass);
//    CheckEquals(ARttiType.IsPublicType,false);
    CheckEquals(ARttiType.TypeSize,SizeOf(TObject));
    CheckEquals(ARttiType.IsManaged,false);
    CheckEquals(ARttiType.BaseType.classname,'TRttiInstanceType');
    CheckEquals(ARttiType.IsInstance,True);
    CheckEquals(ARttiType.AsInstance.DeclaringUnitName,'tests.rtti');
    Check(ARttiType.BaseType.Name='TObject');
    Check(ARttiType.AsInstance.BaseType.Name='TObject');
    CheckEquals(ARttiType.IsOrdinal,False);
    CheckEquals(ARttiType.IsRecord,False);
    CheckEquals(ARttiType.IsSet,False);
  finally
    c.Free;
  end;

end;

procedure TTestCase1.GetTypeInteger;
var
  LContext: TRttiContext;
  LType: TRttiType;
begin
  LContext := TRttiContext.Create;

  LType := LContext.GetType(TypeInfo(integer));
{$ifdef fpc}
  CheckEquals(LType.Name, 'LongInt');
{$else}
  CheckEquals(LType.Name, 'Integer');
{$endif}

  LContext.Free;
end;

procedure TTestCase1.GetTypePointer;
var
  context: TRttiContext;
  t: TRttiType;
  p: TRttiPointerType absolute t;
begin
  context := TRttiContext.Create;
  try
    t := context.GetType(TypeInfo(Pointer));
    Assert(t is TRttiPointerType, 'Type of Pointer is not a TRttiPointerType');
    Assert(not Assigned(p.ReferredType), 'ReferredType of Pointer is not Nil');
    t := context.GetType(TypeInfo(PLongInt));
    Assert(t is TRttiPointerType, 'Type of Pointer is not a TRttiPointerType');
    Assert(Assigned(p.ReferredType), 'ReferredType of PLongInt is Nil');
    Assert(p.ReferredType = context.GetType(TypeInfo(LongInt)), 'ReferredType of PLongInt is not a LongInt');
    t := context.GetType(TypeInfo(PWideChar));
    Assert(t is TRttiPointerType, 'Type of Pointer is not a TRttiPointerType');
    Assert(Assigned(p.ReferredType), 'ReferredType of PWideChar is Nil');
    Assert(p.ReferredType = context.GetType(TypeInfo(WideChar)), 'ReferredType of PWideChar is not a WideChar');
  finally
    context.Free;
  end;
end;

procedure TTestCase1.GetClassProperties;
var
  LContext: TRttiContext;
  LType: TRttiType;
  PropList, PropList2: {$ifdef fpc}specialize{$endif} TArray<TRttiProperty>;
  i: LongInt;
begin
  LContext := TRttiContext.Create;

  LType := LContext.GetType(TypeInfo(TGetClassProperties));
  PropList := LType.GetProperties;

  CheckEquals(4, length(PropList));
  CheckEquals('PubPropRO', PropList[0].Name);
  CheckEquals('PubPropRW', PropList[1].Name);
  CheckEquals('PubPropSetRO', PropList[2].Name);
  CheckEquals('PubPropSetRW', PropList[3].Name);

  LType := LContext.GetType(TypeInfo(TGetClassPropertiesSub));
  PropList2 := LType.GetProperties;

  CheckEquals(Length(PropList), Length(PropList2));
  for i := 0 to High(PropList) do
    Check(PropList[i] = PropList2[i], 'Property instances are not equal');

  LContext.Free;
end;

procedure TTestCase1.GetClassPropertiesValue;
var
  AGetClassProperties: TGetClassProperties;
  LContext: TRttiContext;
  LType: TRttiType;
  AValue: TValue;
begin
  LContext := TRttiContext.Create;

  LType := LContext.GetType(TGetClassProperties);

  AGetClassProperties := TGetClassProperties.Create;
  try
    AGetClassProperties.PubPropRW:=12345;

    AValue := LType.GetProperty('PubPropRW').GetValue(AGetClassProperties);
    CheckEquals(12345, AValue.AsInteger);

  finally
    AGetClassProperties.Free;
  end;

  LContext.Free;
end;

procedure TTestCase1.TestReferenceRawData;
var
  value: TValue;
  str: String;
  intf: IInterface;
  i: LongInt;
  test: TTestRecord;
  arrdyn: TArrayOfLongintDyn;
  arrstat: TArrayOfLongintStatic;
begin
  str := 'Hello World';
  UniqueString(str);
  TValue.Make(@str, TypeInfo(String), value);
  Check(PPointer(value.GetReferenceToRawData)^ = Pointer(str), 'Reference to string data differs');

  intf := TInterfacedObject.Create;
  TValue.Make(@intf, TypeInfo(IInterface), value);
  Check(PPointer(value.GetReferenceToRawData)^ = Pointer(intf), 'Reference to interface data differs');

  i := 42;
  TValue.Make(@i, TypeInfo(LongInt), value);
  Check(value.GetReferenceToRawData <> @i, 'Reference to longint is equal');
  Check(PLongInt(value.GetReferenceToRawData)^ = PLongInt(@i)^, 'Reference to longint data differs');

  test.value1 := 42;
  test.value2 := 'Hello World';
  TValue.Make(@test, TypeInfo(TTestRecord), value);
  Check(value.GetReferenceToRawData <> @test, 'Reference to record is equal');
  Check(PTestRecord(value.GetReferenceToRawData)^.value1 = PTestRecord(@test)^.value1, 'Reference to record data value1 differs');
  Check(PTestRecord(value.GetReferenceToRawData)^.value2 = PTestRecord(@test)^.value2, 'Reference to record data value2 differs');

  SetLength(arrdyn, 3);
  arrdyn[0] := 42;
  arrdyn[1] := 23;
  arrdyn[2] := 49;
  TValue.Make(@arrdyn, TypeInfo(TArrayOfLongintDyn), value);
  Check(PPointer(value.GetReferenceToRawData)^ = Pointer(arrdyn), 'Reference to dynamic array data differs');

  arrstat[0] := 42;
  arrstat[1] := 23;
  arrstat[2] := 49;
  arrstat[3] := 59;
  TValue.Make(@arrstat, TypeInfo(TArrayOfLongintStatic), value);
  Check(value.GetReferenceToRawData <> @arrstat, 'Reference to static array is equal');
  Check(PLongInt(value.GetReferenceToRawData)^ = PLongInt(@arrstat)^, 'Reference to static array data differs');
end;

procedure TTestCase1.TestReferenceRawDataEmpty;
var
  value: TValue;
begin
  TValue.Make(Nil, TypeInfo(String), value);
  Check(Assigned(value.GetReferenceToRawData()), 'Reference to empty String is not assigned');
  Check(not Assigned(PPointer(value.GetReferenceToRawData)^), 'Empty String data is assigned');

  TValue.Make(Nil, TypeInfo(IInterface), value);
  Check(Assigned(value.GetReferenceToRawData()), 'Reference to empty interface is not assigned');
  Check(not Assigned(PPointer(value.GetReferenceToRawData)^), 'Empty interface data is assigned');

  TValue.Make(Nil, TypeInfo(LongInt), value);
  Check(Assigned(value.GetReferenceToRawData()), 'Reference to empty LongInt is not assigned');
  Check(PLongInt(value.GetReferenceToRawData)^ = 0, 'Empty longint data is not 0');

  TValue.Make(Nil, TypeInfo(TTestRecord), value);
  Check(Assigned(value.GetReferenceToRawData()), 'Reference to empty record is not assigned');
  Check(PTestRecord(value.GetReferenceToRawData)^.value1 = 0, 'Empty record data value1 is not 0');
  Check(PTestRecord(value.GetReferenceToRawData)^.value2 = '', 'Empty record data value2 is not empty');

  TValue.Make(Nil, TypeInfo(TArrayOfLongintDyn), value);
  Check(Assigned(value.GetReferenceToRawData()), 'Reference to empty dynamic array is not assigned');
  Check(not Assigned(PPointer(value.GetReferenceToRawData)^), 'Empty dynamic array data is assigned');

  TValue.Make(Nil, TypeInfo(TArrayOfLongintStatic), value);
  Check(Assigned(value.GetReferenceToRawData()), 'Reference to empty static array is not assigned');
  Check(PLongInt(value.GetReferenceToRawData)^ = 0, 'Empty static array data is not 0');
end;

procedure TTestCase1.TestDataSize;
var
  u8: UInt8;
  u16: UInt16;
  u32: UInt32;
  u64: UInt64;
  s8: Int8;
  s16: Int16;
  s32: Int32;
  s64: Int64;
  f32: Single;
  f64: Double;
{$ifdef FPC_HAS_TYPE_EXTENDED}
  f80: Extended;
{$endif}
  fco: Comp;
  fcu: Currency;
  ss: ShortString;
  sa: AnsiString;
  su: UnicodeString;
  sw: WideString;
  o: TObject;
  c: TClass;
  i: IInterface;
  ad: TArrayOfLongintDyn;
  _as: TArrayOfLongintStatic;
  b8: Boolean;
{$ifdef fpc}
  b16: Boolean16;
  b32: Boolean32;
  b64: Boolean64;
{$endif}
  bl8: ByteBool;
  bl16: WordBool;
  bl32: LongBool;
{$ifdef fpc}
  bl64: QWordBool;
{$endif}
  e: TTestEnum;
  s: TTestSet;
  t: TTestRecord;
  p: Pointer;
  proc: TTestProc;
  method: TTestMethod;

  value: TValue;
begin
  TValue.Make(@u8, TypeInfo(UInt8), value);
  CheckEquals(1, value.DataSize, 'Size of UInt8 differs');
  TValue.Make(@u16, TypeInfo(UInt16), value);
  CheckEquals(2, value.DataSize, 'Size of UInt16 differs');
  TValue.Make(@u32, TypeInfo(UInt32), value);
  CheckEquals(4, value.DataSize, 'Size of UInt32 differs');
  TValue.Make(@u64, TypeInfo(UInt64), value);
  CheckEquals(8, value.DataSize, 'Size of UInt64 differs');
  TValue.Make(@s8, TypeInfo(Int8), value);
  CheckEquals(1, value.DataSize, 'Size of Int8 differs');
  TValue.Make(@s16, TypeInfo(Int16), value);
  CheckEquals(2, value.DataSize, 'Size of Int16 differs');
  TValue.Make(@s32, TypeInfo(Int32), value);
  CheckEquals(4, value.DataSize, 'Size of Int32 differs');
  TValue.Make(@s64, TypeInfo(Int64), value);
  CheckEquals(8, value.DataSize, 'Size of Int64 differs');
  TValue.Make(@b8, TypeInfo(Boolean), value);
  CheckEquals(1, value.DataSize, 'Size of Boolean differs');
{$ifdef fpc}
  TValue.Make(@b16, TypeInfo(Boolean16), value);
  CheckEquals(2, value.DataSize, 'Size of Boolean16 differs');
  TValue.Make(@b32, TypeInfo(Boolean32), value);
  CheckEquals(4, value.DataSize, 'Size of Boolean32 differs');
  TValue.Make(@b64, TypeInfo(Boolean64), value);
  CheckEquals(8, value.DataSize, 'Size of Boolean64 differs');
{$endif}
  TValue.Make(@bl8, TypeInfo(ByteBool), value);
  CheckEquals(1, value.DataSize, 'Size of ByteBool differs');
  TValue.Make(@bl16, TypeInfo(WordBool), value);
  CheckEquals(2, value.DataSize, 'Size of WordBool differs');
  TValue.Make(@bl32, TypeInfo(LongBool), value);
  CheckEquals(4, value.DataSize, 'Size of LongBool differs');
{$ifdef fpc}
  TValue.Make(@bl64, TypeInfo(QWordBool), value);
  CheckEquals(8, value.DataSize, 'Size of QWordBool differs');
{$endif}
  TValue.Make(@f32, TypeInfo(Single), value);
  CheckEquals(4, value.DataSize, 'Size of Single differs');
  TValue.Make(@f64, TypeInfo(Double), value);
  CheckEquals(8, value.DataSize, 'Size of Double differs');
{$ifdef FPC_HAS_TYPE_EXTENDED}
  TValue.Make(@f80, TypeInfo(Extended), value);
  CheckEquals(10, value.DataSize, 'Size of Extended differs');
{$endif}
  TValue.Make(@fcu, TypeInfo(Currency), value);
  CheckEquals(SizeOf(Currency), value.DataSize, 'Size of Currency differs');
  TValue.Make(@fco, TypeInfo(Comp), value);
  CheckEquals(SizeOf(Comp), value.DataSize, 'Size of Comp differs');
  ss := '';
  TValue.Make(@ss, TypeInfo(ShortString), value);
  CheckEquals(254, value.DataSize, 'Size ofShortString differs');
  TValue.Make(@sa, TypeInfo(AnsiString), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of AnsiString differs');
  TValue.Make(@sw, TypeInfo(WideString), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of WideString differs');
  TValue.Make(@su, TypeInfo(UnicodeString), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of UnicodeString differs');
  o := TTestValueClass.Create;
  TValue.Make(@o, TypeInfo(TObject), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of TObject differs');
  o.Free;
  c := TObject;
  TValue.Make(@c, TypeInfo(TClass), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of TClass differs');
  TValue.Make(@i, TypeInfo(IInterface), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of IInterface differs');
  TValue.Make(@t, TypeInfo(TTestRecord), value);
  CheckEquals(SizeOf(TTestRecord), value.DataSize, 'Size of TTestRecord differs');
  proc := Nil;
  TValue.Make(@proc, TypeInfo(TTestProc), value);
  CheckEquals(SizeOf(TTestProc), value.DataSize, 'Size of TTestProc differs');
  method := Nil;
  TValue.Make(@method, TypeInfo(TTestMethod), value);
  CheckEquals(SizeOf(TTestMethod), value.DataSize, 'Size of TTestMethod differs');
  TValue.Make(@_as, TypeInfo(TArrayOfLongintStatic), value);
  CheckEquals(SizeOf(TArrayOfLongintStatic), value.DataSize, 'Size of TArrayOfLongintStatic differs');
  TValue.Make(@ad, TypeInfo(TArrayOfLongintDyn), value);
  CheckEquals(SizeOf(TArrayOfLongintDyn), value.DataSize, 'Size of TArrayOfLongintDyn differs');
  TValue.Make(@e, TypeInfo(TTestEnum), value);
  CheckEquals(SizeOf(TTestEnum), value.DataSize, 'Size of TTestEnum differs');
  TValue.Make(@s, TypeInfo(TTestSet), value);
  CheckEquals(SizeOf(TTestSet), value.DataSize, 'Size of TTestSet differs');
  p := Nil;
  TValue.Make(@p, TypeInfo(Pointer), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of Pointer differs');
end;

procedure TTestCase1.TestDataSizeEmpty;
var
  value: TValue;
begin
  TValue.Make(Nil, TypeInfo(UInt8), value);
  CheckEquals(1, value.DataSize, 'Size of UInt8 differs');
  TValue.Make(Nil, TypeInfo(UInt16), value);
  CheckEquals(2, value.DataSize, 'Size of UInt16 differs');
  TValue.Make(Nil, TypeInfo(UInt32), value);
  CheckEquals(4, value.DataSize, 'Size of UInt32 differs');
  TValue.Make(Nil, TypeInfo(UInt64), value);
  CheckEquals(8, value.DataSize, 'Size of UInt64 differs');
  TValue.Make(Nil, TypeInfo(Int8), value);
  CheckEquals(1, value.DataSize, 'Size of Int8 differs');
  TValue.Make(Nil, TypeInfo(Int16), value);
  CheckEquals(2, value.DataSize, 'Size of Int16 differs');
  TValue.Make(Nil, TypeInfo(Int32), value);
  CheckEquals(4, value.DataSize, 'Size of Int32 differs');
  TValue.Make(Nil, TypeInfo(Int64), value);
  CheckEquals(8, value.DataSize, 'Size of Int64 differs');
  TValue.Make(Nil, TypeInfo(Boolean), value);
  CheckEquals(1, value.DataSize, 'Size of Boolean differs');
{$ifdef fpc}
  TValue.Make(Nil, TypeInfo(Boolean16), value);
  CheckEquals(2, value.DataSize, 'Size of Boolean16 differs');
  TValue.Make(Nil, TypeInfo(Boolean32), value);
  CheckEquals(4, value.DataSize, 'Size of Boolean32 differs');
  TValue.Make(Nil, TypeInfo(Boolean64), value);
  CheckEquals(8, value.DataSize, 'Size of Boolean64 differs');
{$endif}
  TValue.Make(Nil, TypeInfo(ByteBool), value);
  CheckEquals(1, value.DataSize, 'Size of ByteBool differs');
  TValue.Make(Nil, TypeInfo(WordBool), value);
  CheckEquals(2, value.DataSize, 'Size of WordBool differs');
  TValue.Make(Nil, TypeInfo(LongBool), value);
  CheckEquals(4, value.DataSize, 'Size of LongBool differs');
{$ifdef fpc}
  TValue.Make(Nil, TypeInfo(QWordBool), value);
  CheckEquals(8, value.DataSize, 'Size of QWordBool differs');
{$endif}
  TValue.Make(Nil, TypeInfo(Single), value);
  CheckEquals(4, value.DataSize, 'Size of Single differs');
  TValue.Make(Nil, TypeInfo(Double), value);
  CheckEquals(8, value.DataSize, 'Size of Double differs');
{$ifdef FPC_HAS_TYPE_EXTENDED}
  TValue.Make(Nil, TypeInfo(Extended), value);
  CheckEquals(10, value.DataSize, 'Size of Extended differs');
{$endif}
  TValue.Make(Nil, TypeInfo(Currency), value);
  CheckEquals(SizeOf(Currency), value.DataSize, 'Size of Currency differs');
  TValue.Make(Nil, TypeInfo(Comp), value);
  CheckEquals(SizeOf(Comp), value.DataSize, 'Size of Comp differs');
  TValue.Make(Nil, TypeInfo(ShortString), value);
  CheckEquals(254, value.DataSize, 'Size of ShortString differs');
  TValue.Make(Nil, TypeInfo(AnsiString), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of Pointer differs');
  TValue.Make(Nil, TypeInfo(WideString), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of WideString differs');
  TValue.Make(Nil, TypeInfo(UnicodeString), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of UnicodeString differs');
  TValue.Make(Nil, TypeInfo(TObject), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of TObject differs');
  TValue.Make(Nil, TypeInfo(TClass), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of TClass differs');
  TValue.Make(Nil, TypeInfo(IInterface), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of IInterface differs');
  TValue.Make(Nil, TypeInfo(TTestRecord), value);
  CheckEquals(SizeOf(TTestRecord), value.DataSize, 'Size of TTestRecord differs');
  TValue.Make(Nil, TypeInfo(TTestProc), value);
  CheckEquals(SizeOf(TTestProc), value.DataSize, 'Size of TTestProc differs');
  TValue.Make(Nil, TypeInfo(TTestMethod), value);
  CheckEquals(SizeOf(TTestMethod), value.DataSize, 'Size of TTestMethod differs');
  TValue.Make(Nil, TypeInfo(TArrayOfLongintStatic), value);
  CheckEquals(SizeOf(TArrayOfLongintStatic), value.DataSize, 'Size of TArrayOfLongintStatic differs');
  TValue.Make(Nil, TypeInfo(TArrayOfLongintDyn), value);
  CheckEquals(SizeOf(TArrayOfLongintDyn), value.DataSize, 'Size of TArrayOfLongintDyn differs');
  TValue.Make(Nil, TypeInfo(TTestEnum), value);
  CheckEquals(SizeOf(TTestEnum), value.DataSize, 'Size of TTestEnum differs');
  TValue.Make(Nil, TypeInfo(TTestSet), value);
  CheckEquals(SizeOf(TTestSet), value.DataSize, 'Size of TTestSet differs');
  TValue.Make(Nil, TypeInfo(Pointer), value);
  CheckEquals(SizeOf(Pointer), value.DataSize, 'Size of Pointer differs');
end;

procedure TTestCase1.TestIsManaged;
begin
  CheckEquals(true, IsManaged(TypeInfo(ansistring)), 'IsManaged for tkAString');
  CheckEquals(true, IsManaged(TypeInfo(widestring)), 'IsManaged for tkWString');
  CheckEquals(true, IsManaged(TypeInfo(Variant)), 'IsManaged for tkVariant');
  CheckEquals(true, IsManaged(TypeInfo(TArrayOfManagedRec)),
    'IsManaged for tkArray (with managed ElType)');
  CheckEquals(true, IsManaged(TypeInfo(TArrayOfString)),
    'IsManaged for tkArray (with managed ElType)');
  CheckEquals(true, IsManaged(TypeInfo(TManagedRec)), 'IsManaged for tkRecord');
  {$ifdef fpc}
  CheckEquals(true, IsManaged(TypeInfo(TManagedRecOp)), 'IsManaged for tkRecord');
  {$endif}
  CheckEquals(true, IsManaged(TypeInfo(IInterface)), 'IsManaged for tkInterface');
  CheckEquals(true, IsManaged(TypeInfo(TManagedObj)), 'IsManaged for tkObject');
  {$ifdef fpc}
  CheckEquals(true, IsManaged(TypeInfo(specialize TArray<byte>)), 'IsManaged for tkDynArray');
  {$else}
  CheckEquals(true, IsManaged(TypeInfo(TArray<byte>)), 'IsManaged for tkDynArray');
  {$endif}
  CheckEquals(true, IsManaged(TypeInfo(unicodestring)), 'IsManaged for tkUString');
  CheckEquals(false, IsManaged(TypeInfo(shortstring)), 'IsManaged for tkSString');
  CheckEquals(false, IsManaged(TypeInfo(Byte)), 'IsManaged for tkInteger');
  CheckEquals(false, IsManaged(TypeInfo(Char)), 'IsManaged for tkChar');
  CheckEquals(false, IsManaged(TypeInfo(TTestEnum)), 'IsManaged for tkEnumeration');
  CheckEquals(false, IsManaged(TypeInfo(Single)), 'IsManaged for tkFloat');
  CheckEquals(false, IsManaged(TypeInfo(TTestSet)), 'IsManaged for tkSet');
  {$ifdef fpc}
  CheckEquals(false, IsManaged(TypeInfo(TTestMethod)), 'IsManaged for tkMethod');
  {$else}
  { Delphi bug (or sabotage). For some reason Delphi considers method pointers to be managed (only in newer versions, probably since XE7) :/ }
  CheckEquals({$if RTLVersion>=28}true{$else}false{$endif}, IsManaged(TypeInfo(TTestMethod)), 'IsManaged for tkMethod');
  {$endif}
  CheckEquals(false, IsManaged(TypeInfo(TArrayOfByte)),
    'IsManaged for tkArray (with non managed ElType)');
  CheckEquals(false, IsManaged(TypeInfo(TArrayOfNonManagedRec)),
    'IsManaged for tkArray (with non managed ElType)');
  CheckEquals(false, IsManaged(TypeInfo(TNonManagedRec)), 'IsManaged for tkRecord');
  CheckEquals(false, IsManaged(TypeInfo(TObject)), 'IsManaged for tkClass');
  CheckEquals(false, IsManaged(TypeInfo(TNonManagedObj)), 'IsManaged for tkObject');
  CheckEquals(false, IsManaged(TypeInfo(WideChar)), 'IsManaged for tkWChar');
  CheckEquals(false, IsManaged(TypeInfo(Boolean)), 'IsManaged for tkBool');
  CheckEquals(false, IsManaged(TypeInfo(Int64)), 'IsManaged for tkInt64');
  CheckEquals(false, IsManaged(TypeInfo(UInt64)), 'IsManaged for tkQWord');
  {$ifdef fpc}
  CheckEquals(false, IsManaged(TypeInfo(ICORBATest)), 'IsManaged for tkInterfaceRaw');
  {$endif}
  CheckEquals(false, IsManaged(TypeInfo(TTestProc)), 'IsManaged for tkProcVar');
  CheckEquals(false, IsManaged(TypeInfo(TTestHelper)), 'IsManaged for tkHelper');
  {$ifdef fpc}
  CheckEquals(false, IsManaged(TypeInfo(file)), 'IsManaged for tkFile');
  {$endif}
  CheckEquals(false, IsManaged(TypeInfo(TClass)), 'IsManaged for tkClassRef');
  CheckEquals(false, IsManaged(TypeInfo(Pointer)), 'IsManaged for tkPointer');
  CheckEquals(false, IsManaged(nil), 'IsManaged for nil');
end;

initialization
{$ifdef fpc}
  RegisterTest(TTestCase1);
{$else fpc}
  RegisterTest(TTestCase1.Suite);
{$endif fpc}
end.

