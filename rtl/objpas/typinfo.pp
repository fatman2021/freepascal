{
    This file is part of the Free Pascal run time library.

    Copyright (c) 1999-2000 by Florian Klaempfl
    member of the Free Pascal development team

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{ This unit provides the same Functionality as the TypInfo Unit }
{ of Delphi                                                     }

unit typinfo;

  interface

{$MODE objfpc}
{$MODESWITCH AdvancedRecords}
{$inline on}
{$macro on}
{$h+}

  uses SysUtils;


// temporary types:

    type

{$MINENUMSIZE 1   this saves a lot of memory }
{$ifdef FPC_RTTI_PACKSET1}
{ for Delphi compatibility }
{$packset 1}
{$endif}

       { this alias and the following constant aliases are for backwards
         compatibility before TTypeKind was moved to System unit }
       TTypeKind = System.TTypeKind;

    const

       tkUnknown = System.tkUnknown;
       tkInteger = System.tkInteger;
       tkChar = System.tkChar;
       tkEnumeration = System.tkEnumeration;
       tkFloat = System.tkFloat;
       tkSet = System.tkSet;
       tkMethod = System.tkMethod;
       tkSString = System.tkSString;
       tkLString = System.tkLString;
       tkAString = System.tkAString;
       tkWString = System.tkWString;
       tkVariant = System.tkVariant;
       tkArray = System.tkArray;
       tkRecord = System.tkRecord;
       tkInterface = System.tkInterface;
       tkClass = System.tkClass;
       tkObject = System.tkObject;
       tkWChar = System.tkWChar;
       tkBool = System.tkBool;
       tkInt64 = System.tkInt64;
       tkQWord = System.tkQWord;
       tkDynArray = System.tkDynArray;
       tkInterfaceRaw = System.tkInterfaceRaw;
       tkProcVar = System.tkProcVar;
       tkUString = System.tkUString;
       tkUChar = System.tkUChar;
       tkHelper = System.tkHelper;
       tkFile = System.tkFile;
       tkClassRef = System.tkClassRef;
       tkPointer = System.tkPointer;

    type

       TOrdType  = (otSByte,otUByte,otSWord,otUWord,otSLong,otULong,otSQWord,otUQWord);

{$ifndef FPUNONE}
       TFloatType = (ftSingle,ftDouble,ftExtended,ftComp,ftCurr);
{$endif}
       TMethodKind = (mkProcedure,mkFunction,mkConstructor,mkDestructor,
                      mkClassProcedure,mkClassFunction,mkClassConstructor,
                      mkClassDestructor,mkOperatorOverload);
       TParamFlag     = (pfVar,pfConst,pfArray,pfAddress,pfReference,pfOut,pfConstRef
                         {$ifndef VER3_0},pfHidden,pfHigh,pfSelf,pfVmt,pfResult{$endif VER3_0}
                         );
       TParamFlags    = set of TParamFlag;
       TIntfFlag      = (ifHasGuid,ifDispInterface,ifDispatch,ifHasStrGUID);
       TIntfFlags     = set of TIntfFlag;
       TIntfFlagsBase = set of TIntfFlag;

       // don't rely on integer values of TCallConv since it includes all conventions
       // which both delphi and fpc support. In the future delphi can support more and
       // fpc own conventions will be shifted/reordered accordinly
       TCallConv = (ccReg, ccCdecl, ccPascal, ccStdCall, ccSafeCall,
                    ccCppdecl, ccFar16, ccOldFPCCall, ccInternProc,
                    ccSysCall, ccSoftFloat, ccMWPascal);

{$push}
{$scopedenums on}
       TSubRegister = (
         None,
         Lo,
         Hi,
         Word,
         DWord,
         QWord,
         FloatSingle,
         FloatDouble,
         FloatQuad,
         MultiMediaSingle,
         MultiMediaDouble,
         MultiMediaWhole,
         MultiMediaX,
         MultiMediaY
       );

       TRegisterType = (
         Invalid,
         Int,
         FP,
         MMX,
         MultiMedia,
         Special,
         Address
       );
{$pop}

{$MINENUMSIZE DEFAULT}

   const
      ptField = 0;
      ptStatic = 1;
      ptVirtual = 2;
      ptConst = 3;

   type
      TTypeKinds = set of TTypeKind;
      ShortStringBase = string[255];

      PParameterLocation = ^TParameterLocation;
      TParameterLocation =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        LocType: Byte;
        function GetRegType: TRegisterType; inline;
        function GetReference: Boolean; inline;
        function GetShiftVal: Int8; inline;
      public
        RegSub: TSubRegister;
        RegNumber: Word;
        { Stack offset if Reference, ShiftVal if not }
        Offset: SizeInt;
        { if Reference then the register is the index register otherwise the
          register in wihch (part of) the parameter resides }
        property Reference: Boolean read GetReference;
        property RegType: TRegisterType read GetRegType;
        { if Reference, otherwise 0 }
        property ShiftVal: Int8 read GetShiftVal;
      end;

      PParameterLocations = ^TParameterLocations;
      TParameterLocations =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetLocation(aIndex: Byte): PParameterLocation; inline;
        function GetTail: Pointer; inline;
      public
        Count: Byte;
        property Location[Index: Byte]: PParameterLocation read GetLocation;
        property Tail: Pointer read GetTail;
      end;

      PVmtFieldEntry = ^TVmtFieldEntry;
      TVmtFieldEntry =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
        FieldOffset: PtrUInt;
        TypeIndex: Word;
        Name: ShortString;
      end;

      PVmtFieldTable = ^TVmtFieldTable;
      TVmtFieldTable =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
        Count: Word;
        ClassTab: Pointer;
        { should be array[Word] of TFieldInfo;  but
          Elements have variant size! force at least proper alignment }
        Fields: array[0..0] of TVmtFieldEntry
      end;

{$PACKRECORDS 1}
      TTypeInfo = record
         Kind : TTypeKind;
         Name : ShortString;
         // here the type data follows as TTypeData record
      end;

      PTypeInfo = ^TTypeInfo;
      PPTypeInfo = ^PTypeInfo;

      PPropData = ^TPropData;

{ Note: these are only for backwards compatibility. New type references should
        only use PPTypeInfo directly! }
{$ifdef ver3_0}
{$define TypeInfoPtr := PTypeInfo}
{$else}
{$define TypeInfoPtr := PPTypeInfo}
{$endif}

{$PACKRECORDS C}
      // members of TTypeData
      TArrayTypeData =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetElType: PTypeInfo; inline;
        function GetDims(aIndex: Byte): PTypeInfo; inline;
      public
        property ElType: PTypeInfo read GetElType;
        property Dims[Index: Byte]: PTypeInfo read GetDims;
      public
        Size: SizeInt;
        ElCount: SizeInt;
        ElTypeRef: TypeInfoPtr;
        DimCount: Byte;
        DimsRef: array[0..255] of TypeInfoPtr;
      end;

      PManagedField = ^TManagedField;
      TManagedField =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetTypeRef: PTypeInfo; inline;
      public
        property TypeRef: PTypeInfo read GetTypeRef;
      public
        TypeRefRef: TypeInfoPtr;
        FldOffset: SizeInt;
      end;

      PInitManagedField = ^TInitManagedField;
      TInitManagedField = TManagedField;

      PProcedureParam = ^TProcedureParam;
      TProcedureParam =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetParamType: PTypeInfo; inline;
        function GetFlags: Byte; inline;
      public
        property ParamType: PTypeInfo read GetParamType;
        property Flags: Byte read GetFlags;
      public
        ParamFlags: TParamFlags;
        ParamTypeRef: TypeInfoPtr;
        Name: ShortString;
      end;

      TProcedureSignature =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetResultType: PTypeInfo; inline;
      public
        property ResultType: PTypeInfo read GetResultType;
      public
        Flags: Byte;
        CC: TCallConv;
        ResultTypeRef: TypeInfoPtr;
        ParamCount: Byte;
        {Params: array[0..ParamCount - 1] of TProcedureParam;}
        function GetParam(ParamIndex: Integer): PProcedureParam;
      end;

      PVmtMethodParam = ^TVmtMethodParam;
      TVmtMethodParam =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetParaLocs: PParameterLocations; inline;
        function GetTail: Pointer; inline;
        function GetNext: PVmtMethodParam; inline;
      public
        ParamType: PPTypeInfo;
        Flags: TParamFlags;
        Name: ShortString;
        { ParaLocs: TParameterLocations; }
        property ParaLocs: PParameterLocations read GetParaLocs;
        property Tail: Pointer read GetTail;
        property Next: PVmtMethodParam read GetNext;
      end;

      PIntfMethodEntry = ^TIntfMethodEntry;
      TIntfMethodEntry =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetParam(Index: Word): PVmtMethodParam;
        function GetResultLocs: PParameterLocations; inline;
        function GetTail: Pointer; inline;
        function GetNext: PIntfMethodEntry; inline;
      public
        ResultType: PPTypeInfo;
        CC: TCallConv;
        Kind: TMethodKind;
        ParamCount: Word;
        StackSize: SizeInt;
        Name: ShortString;
        { Params: array[0..ParamCount - 1] of TVmtMethodParam }
        { ResultLocs: TParameterLocations (if ResultType != Nil) }
        property Param[Index: Word]: PVmtMethodParam read GetParam;
        property ResultLocs: PParameterLocations read GetResultLocs;
        property Tail: Pointer read GetTail;
        property Next: PIntfMethodEntry read GetNext;
      end;

      PIntfMethodTable = ^TIntfMethodTable;
      TIntfMethodTable =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetMethod(Index: Word): PIntfMethodEntry;
      public
        Count: Word;
        { $FFFF if there is no further info, or the value of Count }
        RTTICount: Word;
        { Entry: array[0..Count - 1] of TIntfMethodEntry }
        property Method[Index: Word]: PIntfMethodEntry read GetMethod;
      end;

      PRecInitData = ^TRecInitData;
      TRecInitData =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
        Terminator: Pointer;
        Size: Integer;
{$ifdef FPC_HAS_MANAGEMENT_OPERATORS}
        ManagementOp: Pointer;
{$endif}
        ManagedFieldCount: Integer;
        { ManagedFields: array[0..ManagedFieldCount - 1] of TInitManagedField ; }
      end;

      PInterfaceData = ^TInterfaceData;
      TInterfaceData =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetUnitName: ShortString; inline;
        function GetPropertyTable: PPropData; inline;
        function GetMethodTable: PIntfMethodTable; inline;
      public
        Parent: PPTypeInfo;
        Flags: TIntfFlagsBase;
        GUID: TGUID;
        property UnitName: ShortString read GetUnitName;
        property PropertyTable: PPropData read GetPropertyTable;
        property MethodTable: PIntfMethodTable read GetMethodTable;
      private
        UnitNameField: ShortString;
        { PropertyTable: TPropData }
        { MethodTable: TIntfMethodTable }
      end;

      PInterfaceRawData = ^TInterfaceRawData;
      TInterfaceRawData =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetUnitName: ShortString; inline;
        function GetIIDStr: ShortString; inline;
        function GetPropertyTable: PPropData; inline;
        function GetMethodTable: PIntfMethodTable; inline;
      public
        Parent: PPTypeInfo;
        Flags : TIntfFlagsBase;
        IID: TGUID;
        property UnitName: ShortString read GetUnitName;
        property IIDStr: ShortString read GetIIDStr;
        property PropertyTable: PPropData read GetPropertyTable;
        property MethodTable: PIntfMethodTable read GetMethodTable;
      private
        UnitNameField: ShortString;
        { IIDStr: ShortString; }
        { PropertyTable: TPropData }
      end;

      PClassData = ^TClassData;
      TClassData =
      {$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
      {$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetUnitName: ShortString; inline;
        function GetPropertyTable: PPropData; inline;
      public
        ClassType : TClass;
        Parent : PPTypeInfo;
        PropCount : SmallInt;
        property UnitName: ShortString read GetUnitName;
        property PropertyTable: PPropData read GetPropertyTable;
      private
        UnitNameField : ShortString;
        { PropertyTable: TPropData }
      end;

      PTypeData = ^TTypeData;
      TTypeData =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetBaseType: PTypeInfo; inline;
        function GetCompType: PTypeInfo; inline;
        function GetParentInfo: PTypeInfo; inline;
{$ifndef VER3_0}        
        function GetRecInitData: PRecInitData; inline;
{$endif}
        function GetHelperParent: PTypeInfo; inline;
        function GetExtendedInfo: PTypeInfo; inline;
        function GetIntfParent: PTypeInfo; inline;
        function GetRawIntfParent: PTypeInfo; inline;
        function GetIIDStr: ShortString; inline;
        function GetElType: PTypeInfo; inline;
        function GetElType2: PTypeInfo; inline;
        function GetInstanceType: PTypeInfo; inline;
        function GetRefType: PTypeInfo; inline;
      public
        { tkEnumeration }
        property BaseType: PTypeInfo read GetBaseType;
        { tkSet }
        property CompType: PTypeInfo read GetCompType;
        { tkClass }
        property ParentInfo: PTypeInfo read GetParentInfo;
        { tkRecord }
{$ifndef VER3_0}        
        property RecInitData: PRecInitData read GetRecInitData;
{$endif}
        { tkHelper }
        property HelperParent: PTypeInfo read GetHelperParent;
        property ExtendedInfo: PTypeInfo read GetExtendedInfo;
        { tkInterface }
        property IntfParent: PTypeInfo read GetIntfParent;
        { tkInterfaceRaw }
        property RawIntfParent: PTypeInfo read GetRawIntfParent;
        property IIDStr: ShortString read GetIIDStr;
        { tkDynArray }
        property ElType2: PTypeInfo read GetElType2;
        property ElType: PTypeInfo read GetElType;
        { tkClassRef }
        property InstanceType: PTypeInfo read GetInstanceType;
        { tkPointer }
        property RefType: PTypeInfo read GetRefType;
      public
         case TTypeKind of
            tkUnKnown,tkLString,tkWString,tkVariant,tkUString:
              ();
            tkAString:
              (CodePage: Word);
{$ifndef VER3_0}
            tkInt64,tkQWord,
{$endif VER3_0}
            tkInteger,tkChar,tkEnumeration,tkBool,tkWChar,tkSet:
              (OrdType : TOrdType;
               case TTypeKind of
                  tkInteger,tkChar,tkEnumeration,tkBool,tkWChar : (
                    MinValue,MaxValue : Longint;
                    case TTypeKind of
                      tkEnumeration:
                        (
                        BaseTypeRef : TypeInfoPtr;
                        NameList : ShortString;
                        {EnumUnitName: ShortString;})
                    );
{$ifndef VER3_0}
                  {tkBool with OrdType=otSQWord }
                  tkInt64:
                    (MinInt64Value, MaxInt64Value: Int64);
                  {tkBool with OrdType=otUQWord }
                  tkQWord:
                    (MinQWordValue, MaxQWordValue: QWord);
{$endif VER3_0}
                  tkSet:
                    (
{$ifndef VER3_0}
                     SetSize : SizeInt;
{$endif VER3_0}
                     CompTypeRef : TypeInfoPtr
                    )
              );
{$ifndef FPUNONE}
            tkFloat:
              (FloatType : TFloatType);
{$endif}
            tkSString:
              (MaxLength : Byte);
            tkClass:
              (ClassType : TClass;
               ParentInfoRef : TypeInfoPtr;
               PropCount : SmallInt;
               UnitName : ShortString
               // here the properties follow as array of TPropInfo
              );
            tkRecord:
              (
{$ifndef VER3_0}
                RecInitInfo: Pointer; { points to TTypeInfo followed by init table }
{$endif VER3_0}
                RecSize: Integer;
                case Boolean of
                  False: (ManagedFldCount: Integer deprecated 'Use RecInitData^.ManagedFieldCount or TotalFieldCount depending on your use case');
                  True: (TotalFieldCount: Integer);
                {ManagedFields: array[1..TotalFieldCount] of TManagedField}
              );
            tkHelper:
              (HelperParentRef : TypeInfoPtr;
               ExtendedInfoRef : TypeInfoPtr;
               HelperProps : SmallInt;
               HelperUnit : ShortString
               // here the properties follow as array of TPropInfo
              );
            tkMethod:
              (MethodKind : TMethodKind;
               ParamCount : Byte;
               ParamList : array[0..1023] of Char
             {in reality ParamList is a array[1..ParamCount] of:
                  record
                    Flags : TParamFlags;
                    ParamName : ShortString;
                    TypeName : ShortString;
                  end;
              followed by
                  ResultType : ShortString     // for mkFunction, mkClassFunction only
                  ResultTypeRef : PPTypeInfo;  // for mkFunction, mkClassFunction only
                  CC : TCallConv;
                  ParamTypeRefs : array[1..ParamCount] of PPTypeInfo;}
              );
            tkProcVar:
              (ProcSig: TProcedureSignature);
{$ifdef VER3_0}
            tkInt64:
              (MinInt64Value, MaxInt64Value: Int64);
            tkQWord:
              (MinQWordValue, MaxQWordValue: QWord);
{$endif VER3_0}
            tkInterface:
              (
               IntfParentRef: TypeInfoPtr;
               IntfFlags : TIntfFlagsBase;
               GUID: TGUID;
               IntfUnit: ShortString;
               { PropertyTable: TPropData }
               { MethodTable: TIntfMethodTable }
              );
            tkInterfaceRaw:
              (
               RawIntfParentRef: TypeInfoPtr;
               RawIntfFlags : TIntfFlagsBase;
               IID: TGUID;
               RawIntfUnit: ShortString;
               { IIDStr: ShortString; }
               { PropertyTable: TPropData }
              );
            tkArray:
              (ArrayData: TArrayTypeData);
            tkDynArray:
              (
              elSize     : PtrUInt;
              elType2Ref : TypeInfoPtr;
              varType    : Longint;
              elTypeRef  : TypeInfoPtr;
              DynUnitName: ShortStringBase
              );
            tkClassRef:
              (InstanceTypeRef: TypeInfoPtr);
            tkPointer:
              (RefTypeRef: TypeInfoPtr);
      end;

      PPropInfo = ^TPropInfo;

      TPropData =
{$ifndef FPC_REQUIRES_PROPER_ALIGNMENT}
      packed
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
      record
      private
        function GetProp(Index: Word): PPropInfo;
        function GetTail: Pointer; inline;
      public
        PropCount : Word;
        PropList : record _alignmentdummy : ptrint; end;
        property Prop[Index: Word]: PPropInfo read GetProp;
        property Tail: Pointer read GetTail;
      end;

{$PACKRECORDS 1}
      TPropInfo = packed record
      private
        function GetPropType: PTypeInfo; inline;
        function GetTail: Pointer; inline;
        function GetNext: PPropInfo; inline;
      public
        PropTypeRef : TypeInfoPtr;
        GetProc : CodePointer;
        SetProc : CodePointer;
        StoredProc : CodePointer;
        Index : Integer;
        Default : Longint;
        NameIndex : SmallInt;

        // contains the type of the Get/Set/Storedproc, see also ptxxx
        // bit 0..1 GetProc
        //     2..3 SetProc
        //     4..5 StoredProc
        //     6 : true, constant index property
        PropProcs : Byte;

        Name : ShortString;
        property PropType: PTypeInfo read GetPropType;
        property Tail: Pointer read GetTail;
        property Next: PPropInfo read GetNext;
      end;

      TProcInfoProc = Procedure(PropInfo : PPropInfo) of object;

      PPropList = ^TPropList;
      TPropList = array[0..{$ifdef cpu16}(32768 div sizeof(PPropInfo))-2{$else}65535{$endif}] of PPropInfo;

   const
      tkString = tkSString;
      tkProcedure = tkProcVar; // for compatibility with Delphi
      tkAny = [Low(TTypeKind)..High(TTypeKind)];
      tkMethods = [tkMethod];
      tkProperties = tkAny-tkMethods-[tkUnknown];

// general property handling
Function GetTypeData(TypeInfo : PTypeInfo) : PTypeData;
Function AlignTypeData(p : Pointer) : Pointer; inline;

Function GetPropInfo(TypeInfo: PTypeInfo;const PropName: string): PPropInfo;
Function GetPropInfo(TypeInfo: PTypeInfo;const PropName: string; AKinds: TTypeKinds): PPropInfo;
Function GetPropInfo(Instance: TObject; const PropName: string): PPropInfo;
Function GetPropInfo(Instance: TObject; const PropName: string; AKinds: TTypeKinds): PPropInfo;
Function GetPropInfo(AClass: TClass; const PropName: string): PPropInfo;
Function GetPropInfo(AClass: TClass; const PropName: string; AKinds: TTypeKinds): PPropInfo;

Function FindPropInfo(Instance: TObject; const PropName: string): PPropInfo;
Function FindPropInfo(Instance: TObject; const PropName: string; AKinds: TTypeKinds): PPropInfo;
Function FindPropInfo(AClass: TClass; const PropName: string): PPropInfo;
Function FindPropInfo(AClass: TClass; const PropName: string; AKinds: TTypeKinds): PPropInfo;

Procedure GetPropInfos(TypeInfo: PTypeInfo; PropList: PPropList);
Function GetPropList(TypeInfo: PTypeInfo; TypeKinds: TTypeKinds; PropList: PPropList; Sorted: boolean = true): longint;
Function GetPropList(TypeInfo: PTypeInfo; out PropList: PPropList): SizeInt;
function GetPropList(AClass: TClass; out PropList: PPropList): Integer;
function GetPropList(Instance: TObject; out PropList: PPropList): Integer;


// Property information routines.
Function IsStoredProp(Instance: TObject;PropInfo : PPropInfo) : Boolean;
Function IsStoredProp(Instance: TObject; const PropName: string): Boolean;
Function IsPublishedProp(Instance: TObject; const PropName: string): Boolean;
Function IsPublishedProp(AClass: TClass; const PropName: string): Boolean;
Function PropType(Instance: TObject; const PropName: string): TTypeKind;
Function PropType(AClass: TClass; const PropName: string): TTypeKind;
Function PropIsType(Instance: TObject; const PropName: string; TypeKind: TTypeKind): Boolean;
Function PropIsType(AClass: TClass; const PropName: string; TypeKind: TTypeKind): Boolean;

// subroutines to read/write properties
Function  GetOrdProp(Instance: TObject; PropInfo : PPropInfo) : Int64;
Function  GetOrdProp(Instance: TObject; const PropName: string): Int64;
Procedure SetOrdProp(Instance: TObject; PropInfo : PPropInfo;  Value : Int64);
Procedure SetOrdProp(Instance: TObject; const PropName: string; Value: Int64);

Function  GetEnumProp(Instance: TObject; const PropName: string): string;
Function  GetEnumProp(Instance: TObject; const PropInfo: PPropInfo): string;
Procedure SetEnumProp(Instance: TObject; const PropName: string;const Value: string);
Procedure SetEnumProp(Instance: TObject; const PropInfo: PPropInfo;const Value: string);

Function  GetSetProp(Instance: TObject; const PropName: string): string;
Function  GetSetProp(Instance: TObject; const PropName: string; Brackets: Boolean): string;
Function  GetSetProp(Instance: TObject; const PropInfo: PPropInfo; Brackets: Boolean): string;
Procedure SetSetProp(Instance: TObject; const PropName: string; const Value: string);
Procedure SetSetProp(Instance: TObject; const PropInfo: PPropInfo; const Value: string);

Function  GetStrProp(Instance: TObject; PropInfo : PPropInfo) : Ansistring;
Function  GetStrProp(Instance: TObject; const PropName: string): string;
Procedure SetStrProp(Instance: TObject; const PropName: string; const Value: AnsiString);
Procedure SetStrProp(Instance: TObject; PropInfo : PPropInfo; const Value : Ansistring);

Function GetWideStrProp(Instance: TObject; PropInfo: PPropInfo): WideString;
Function GetWideStrProp(Instance: TObject; const PropName: string): WideString;
Procedure SetWideStrProp(Instance: TObject; const PropName: string; const Value: WideString);
Procedure SetWideStrProp(Instance: TObject; PropInfo: PPropInfo; const Value: WideString);

Function GetUnicodeStrProp(Instance: TObject; PropInfo: PPropInfo): UnicodeString;
Function GetUnicodeStrProp(Instance: TObject; const PropName: string): UnicodeString;
Procedure SetUnicodeStrProp(Instance: TObject; const PropName: string; const Value: UnicodeString);
Procedure SetUnicodeStrProp(Instance: TObject; PropInfo: PPropInfo; const Value: UnicodeString);

Function GetRawbyteStrProp(Instance: TObject; PropInfo: PPropInfo): RawByteString;
Function GetRawByteStrProp(Instance: TObject; const PropName: string): RawByteString;
Procedure SetRawByteStrProp(Instance: TObject; const PropName: string; const Value: RawByteString);
Procedure SetRawByteStrProp(Instance: TObject; PropInfo: PPropInfo; const Value: RawByteString);


{$ifndef FPUNONE}
Function  GetFloatProp(Instance: TObject; PropInfo : PPropInfo) : Extended;
Function  GetFloatProp(Instance: TObject; const PropName: string): Extended;
Procedure SetFloatProp(Instance: TObject; const PropName: string; Value: Extended);
Procedure SetFloatProp(Instance: TObject; PropInfo : PPropInfo;  Value : Extended);
{$endif}

Function  GetObjectProp(Instance: TObject; const PropName: string): TObject;
Function  GetObjectProp(Instance: TObject; const PropName: string; MinClass: TClass): TObject;
Function  GetObjectProp(Instance: TObject; PropInfo: PPropInfo): TObject;
Function  GetObjectProp(Instance: TObject; PropInfo: PPropInfo; MinClass: TClass): TObject;
Procedure SetObjectProp(Instance: TObject; const PropName: string; Value: TObject);
Procedure SetObjectProp(Instance: TObject; PropInfo: PPropInfo; Value: TObject);
Function  GetObjectPropClass(Instance: TObject; const PropName: string): TClass;
Function  GetObjectPropClass(AClass: TClass; const PropName: string): TClass;

Function  GetMethodProp(Instance: TObject; PropInfo: PPropInfo) : TMethod;
Function  GetMethodProp(Instance: TObject; const PropName: string): TMethod;
Procedure SetMethodProp(Instance: TObject; PropInfo: PPropInfo;  const Value : TMethod);
Procedure SetMethodProp(Instance: TObject; const PropName: string; const Value: TMethod);

Function  GetInt64Prop(Instance: TObject; PropInfo: PPropInfo): Int64;
Function  GetInt64Prop(Instance: TObject; const PropName: string): Int64;
Procedure SetInt64Prop(Instance: TObject; PropInfo: PPropInfo;  const Value: Int64);
Procedure SetInt64Prop(Instance: TObject; const PropName: string;  const Value: Int64);

Function GetPropValue(Instance: TObject; const PropName: string): Variant;
Function GetPropValue(Instance: TObject; const PropName: string; PreferStrings: Boolean): Variant;
Function GetPropValue(Instance: TObject; PropInfo: PPropInfo): Variant;
Function GetPropValue(Instance: TObject; PropInfo: PPropInfo; PreferStrings: Boolean): Variant;
Procedure SetPropValue(Instance: TObject; const PropName: string; const Value: Variant);
Procedure SetPropValue(Instance: TObject; PropInfo: PPropInfo; const Value: Variant);
Function  GetVariantProp(Instance: TObject; PropInfo : PPropInfo): Variant;
Function  GetVariantProp(Instance: TObject; const PropName: string): Variant;
Procedure SetVariantProp(Instance: TObject; const PropName: string; const Value: Variant);
Procedure SetVariantProp(Instance: TObject; PropInfo : PPropInfo; const Value: Variant);

function GetInterfaceProp(Instance: TObject; const PropName: string): IInterface;
function GetInterfaceProp(Instance: TObject; PropInfo: PPropInfo): IInterface;
procedure SetInterfaceProp(Instance: TObject; const PropName: string; const Value: IInterface);
procedure SetInterfaceProp(Instance: TObject; PropInfo: PPropInfo; const Value: IInterface);

function GetRawInterfaceProp(Instance: TObject; const PropName: string): Pointer;
function GetRawInterfaceProp(Instance: TObject; PropInfo: PPropInfo): Pointer;
procedure SetRawInterfaceProp(Instance: TObject; const PropName: string; const Value: Pointer);
procedure SetRawInterfaceProp(Instance: TObject; PropInfo: PPropInfo; const Value: Pointer);

function GetDynArrayProp(Instance: TObject; const PropName: string): Pointer;
function GetDynArrayProp(Instance: TObject; PropInfo: PPropInfo): Pointer;
procedure SetDynArrayProp(Instance: TObject; const PropName: string; const Value: Pointer);
procedure SetDynArrayProp(Instance: TObject; PropInfo: PPropInfo; const Value: Pointer);

// Auxiliary routines, which may be useful
Function GetEnumName(TypeInfo : PTypeInfo;Value : Integer) : string;
Function GetEnumValue(TypeInfo : PTypeInfo;const Name : string) : Integer;
function GetEnumNameCount(enum1: PTypeInfo): SizeInt;
procedure AddEnumElementAliases(aTypeInfo: PTypeInfo; const aNames: array of string; aStartValue: Integer = 0);
procedure RemoveEnumElementAliases(aTypeInfo: PTypeInfo);
function GetEnumeratedAliasValue(aTypeInfo: PTypeInfo; const aName: string): Integer;

function SetToString(TypeInfo: PTypeInfo; Value: Integer; Brackets: Boolean) : String;
function SetToString(PropInfo: PPropInfo; Value: Integer; Brackets: Boolean) : String;
function SetToString(PropInfo: PPropInfo; Value: Integer) : String;
function StringToSet(PropInfo: PPropInfo; const Value: string): Integer;
function StringToSet(TypeInfo: PTypeInfo; const Value: string): Integer;

const
    BooleanIdents: array[Boolean] of String = ('False', 'True');
    DotSep: String = '.';

Type
  EPropertyError  = Class(Exception);
  TGetPropValue   = Function (Instance: TObject; PropInfo: PPropInfo; PreferStrings: Boolean) : Variant;
  TSetPropValue   = Procedure (Instance: TObject; PropInfo: PPropInfo; const Value: Variant);
  TGetVariantProp = Function (Instance: TObject; PropInfo : PPropInfo): Variant;
  TSetVariantProp = Procedure (Instance: TObject; PropInfo : PPropInfo; const Value: Variant);

  EPropertyConvertError = class(Exception); // Not used (yet), but defined for compatibility.

Const
  OnGetPropValue   : TGetPropValue = Nil;
  OnSetPropValue   : TSetPropValue = Nil;
  OnGetVariantprop : TGetVariantProp = Nil;
  OnSetVariantprop : TSetVariantProp = Nil;

{ for inlining }
function DerefTypeInfoPtr(Info: TypeInfoPtr): PTypeInfo; inline;

Implementation

uses rtlconsts;

type
  PMethod = ^TMethod;

{ ---------------------------------------------------------------------
  Auxiliary methods
  ---------------------------------------------------------------------}

function aligntoptr(p : pointer) : pointer;inline;
   begin
{$ifdef m68k}
     result:=AlignTypeData(p);
{$else m68k}
{$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
     result:=align(p,sizeof(p));
{$else FPC_REQUIRES_PROPER_ALIGNMENT}
     result:=p;
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
{$endif m68k}
   end;


function DerefTypeInfoPtr(Info: TypeInfoPtr): PTypeInfo; inline;
begin
{$ifdef ver3_0}
  Result := Info;
{$else}
  if not Assigned(Info) then
    Result := Nil
  else
    Result := Info^;
{$endif}
end;


Function GetEnumName(TypeInfo : PTypeInfo;Value : Integer) : string;

  Var PS : PShortString;
      PT : PTypeData;

begin
  PT:=GetTypeData(TypeInfo);
  if TypeInfo^.Kind=tkBool then
    begin
      case Value of
        0,1:
          Result:=BooleanIdents[Boolean(Value)];
        else
          Result:='';
      end;
    end
 else
   begin
     PS:=@PT^.NameList;
     dec(Value,PT^.MinValue);
     While Value>0 Do
       begin
         PS:=PShortString(pointer(PS)+PByte(PS)^+1);
         Dec(Value);
       end;
     Result:=PS^;
   end;
end;


Function GetEnumValue(TypeInfo : PTypeInfo;const Name : string) : Integer;

  Var PS : PShortString;
      PT : PTypeData;
      Count : longint;
      sName: shortstring;

begin
  If Length(Name)=0 then
    exit(-1);
  sName := Name;
  PT:=GetTypeData(TypeInfo);
  Count:=0;
  Result:=-1;

  if TypeInfo^.Kind=tkBool then
    begin
    If CompareText(BooleanIdents[false],Name)=0 then
      result:=0
    else if CompareText(BooleanIdents[true],Name)=0 then
      result:=1;
    end
 else
   begin
     PS:=@PT^.NameList;
     While (Result=-1) and (PByte(PS)^<>0) do
       begin
         If ShortCompareText(PS^, sName) = 0 then
           Result:=Count+PT^.MinValue;
         PS:=PShortString(pointer(PS)+PByte(PS)^+1);
         Inc(Count);
       end;
     if Result=-1 then
       Result:=GetEnumeratedAliasValue(TypeInfo,Name);
   end;
end;


function GetEnumNameCount(enum1: PTypeInfo): SizeInt;
var
  PS: PShortString;
  PT: PTypeData;
  Count: SizeInt;
begin
  PT:=GetTypeData(enum1);
  if enum1^.Kind=tkBool then
    Result:=2
  else
    begin
      Count:=0;
      Result:=0;

      PS:=@PT^.NameList;
      While (PByte(PS)^<>0) do
        begin
          PS:=PShortString(pointer(PS)+PByte(PS)^+1);
          Inc(Count);
        end;
      { the last string is the unit name }
      Result := Count - 1;
    end;
end;


Function SetToString(PropInfo: PPropInfo; Value: Integer; Brackets: Boolean) : String;

begin
  Result:=SetToString(PropInfo^.PropType,Value,Brackets);
end;

Function SetToString(TypeInfo: PTypeInfo; Value: Integer; Brackets: Boolean) : String;

type
  tsetarr = bitpacked array[0..SizeOf(Integer)*8-1] of 0..1;
Var
  I : Integer;
  PTI : PTypeInfo;

begin
{$if defined(FPC_BIG_ENDIAN)}
  { On big endian systems, set element 0 is in the most significant bit,
    and the same goes for the elements of bitpacked arrays there.  }
  case GetTypeData(TypeInfo)^.OrdType of
    otSByte,otUByte: Value:=Value shl (SizeOf(Integer)*8-8);
    otSWord,otUWord: Value:=Value shl (SizeOf(Integer)*8-16);
  end;
{$endif}

  PTI:=GetTypeData(TypeInfo)^.CompType;
  Result:='';
  For I:=0 to SizeOf(Integer)*8-1 do
    begin
      if (tsetarr(Value)[i]<>0) then
        begin
          If Result='' then
            Result:=GetEnumName(PTI,i)
          else
            Result:=Result+','+GetEnumName(PTI,I);
        end;
    end;
  if Brackets then
    Result:='['+Result+']';
end;


Function SetToString(PropInfo: PPropInfo; Value: Integer) : String;

begin
  Result:=SetToString(PropInfo,Value,False);
end;


Const
  SetDelim = ['[',']',',',' '];

Function GetNextElement(Var S : String) : String;
Var
  J : Integer;
begin
  J:=1;
  Result:='';
  If Length(S)>0 then
    begin
      While (J<=Length(S)) and Not (S[j] in SetDelim) do
        Inc(j);
      Result:=Copy(S,1,j-1);
      Delete(S,1,j);
    end;
end;

Function StringToSet(PropInfo: PPropInfo; const Value: string): Integer;

begin
  Result:=StringToSet(PropInfo^.PropType,Value);
end;

Function StringToSet(TypeInfo: PTypeInfo; const Value: string): Integer;
Var
  S,T : String;
  I : Integer;
  PTI : PTypeInfo;

begin
  Result:=0;
  PTI:=GetTypeData(TypeInfo)^.Comptype;
  S:=Value;
  I:=1;
  If Length(S)>0 then
    begin
      While (I<=Length(S)) and (S[i] in SetDelim) do
        Inc(I);
      Delete(S,1,i-1);
    end;
  While (S<>'') do
    begin
      T:=GetNextElement(S);
      if T<>'' then
        begin
          I:=GetEnumValue(PTI,T);
          if (I<0) then
            raise EPropertyError.CreateFmt(SErrUnknownEnumValue, [T]);
          Result:=Result or (1 shl i);
        end;
    end;
end;


Function AlignTypeData(p : Pointer) : Pointer;
{$packrecords c}
  type
    TAlignCheck = record
      b : byte;
      q : qword;
    end;
{$packrecords default}
begin
{$ifdef FPC_REQUIRES_PROPER_ALIGNMENT}
{$ifdef VER3_0}
  Result:=Pointer(align(p,SizeOf(Pointer)));
{$else VER3_0}
  Result:=Pointer(align(p,PtrInt(@TAlignCheck(nil^).q)))
{$endif VER3_0}
{$else FPC_REQUIRES_PROPER_ALIGNMENT}
  Result:=p;
{$endif FPC_REQUIRES_PROPER_ALIGNMENT}
end;


Function GetTypeData(TypeInfo : PTypeInfo) : PTypeData;
begin
  GetTypeData:=AlignTypeData(pointer(TypeInfo)+2+PByte(pointer(TypeInfo)+1)^);
end;


{ ---------------------------------------------------------------------
  Basic Type information functions.
  ---------------------------------------------------------------------}

Function GetPropInfo(TypeInfo : PTypeInfo;const PropName : string) : PPropInfo;
var
  hp : PTypeData;
  i : longint;
  p : shortstring;
  pd : ^TPropData;
begin
  P:=PropName;  // avoid Ansi<->short conversion in a loop
  while Assigned(TypeInfo) do
    begin
      // skip the name
      hp:=GetTypeData(Typeinfo);
      // the class info rtti the property rtti follows immediatly
      pd:=aligntoptr(pointer(pointer(@hp^.UnitName)+Length(hp^.UnitName)+1));
      Result:=PPropInfo(@pd^.PropList);
      for i:=1 to pd^.PropCount do
        begin
          // found a property of that name ?
          if ShortCompareText(Result^.Name, P) = 0 then
            exit;
          // skip to next property
          Result:=PPropInfo(aligntoptr(pointer(@Result^.Name)+byte(Result^.Name[0])+1));
        end;
      // parent class
      Typeinfo:=hp^.ParentInfo;
    end;
  Result:=Nil;
end;


Function GetPropInfo(TypeInfo : PTypeInfo;const PropName : string; Akinds : TTypeKinds) : PPropInfo;
begin
  Result:=GetPropInfo(TypeInfo,PropName);
  If (Akinds<>[]) then
    If (Result<>Nil) then
      If Not (Result^.PropType^.Kind in AKinds) then
        Result:=Nil;
end;


Function GetPropInfo(AClass: TClass; const PropName: string; AKinds: TTypeKinds) : PPropInfo;
begin
  Result:=GetPropInfo(PTypeInfo(AClass.ClassInfo),PropName,AKinds);
end;


Function GetPropInfo(Instance: TObject; const PropName: string; AKinds: TTypeKinds) : PPropInfo;
begin
  Result:=GetPropInfo(Instance.ClassType,PropName,AKinds);
end;


Function GetPropInfo(Instance: TObject; const PropName: string): PPropInfo;
begin
  Result:=GetPropInfo(Instance,PropName,[]);
end;


Function GetPropInfo(AClass: TClass; const PropName: string): PPropInfo;
begin
  Result:=GetPropInfo(AClass,PropName,[]);
end;


Function FindPropInfo(Instance: TObject; const PropName: string): PPropInfo;
begin
  result:=GetPropInfo(Instance, PropName);
  if Result=nil then
    Raise EPropertyError.CreateFmt(SErrPropertyNotFound, [PropName]);
end;


Function FindPropInfo(Instance: TObject; const PropName: string; AKinds: TTypeKinds): PPropInfo;
begin
  result:=GetPropInfo(Instance, PropName, AKinds);
  if Result=nil then
    Raise EPropertyError.CreateFmt(SErrPropertyNotFound, [PropName]);
end;


Function FindPropInfo(AClass: TClass; const PropName: string): PPropInfo;
begin
  result:=GetPropInfo(AClass, PropName);
  if result=nil then
    Raise EPropertyError.CreateFmt(SErrPropertyNotFound, [PropName]);
end;


Function FindPropInfo(AClass: TClass; const PropName: string; AKinds: TTypeKinds): PPropInfo;
begin
  result:=GetPropInfo(AClass, PropName, AKinds);
  if result=nil then
    Raise EPropertyError.CreateFmt(SErrPropertyNotFound, [PropName]);
end;


Function IsStoredProp(Instance : TObject;PropInfo : PPropInfo) : Boolean;
type
  TBooleanIndexFunc=function(Index:integer):boolean of object;
  TBooleanFunc=function:boolean of object;
var
  AMethod : TMethod;
begin
  case (PropInfo^.PropProcs shr 4) and 3 of
    ptField:
      Result:=PBoolean(Pointer(Instance)+PtrUInt(PropInfo^.StoredProc))^;
    ptConst:
      Result:=LongBool(PropInfo^.StoredProc);
    ptStatic,
    ptVirtual:
      begin
        if (PropInfo^.PropProcs shr 4) and 3=ptstatic then
          AMethod.Code:=PropInfo^.StoredProc
        else
          AMethod.Code:=pcodepointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.StoredProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
           Result:=TBooleanIndexFunc(AMethod)(PropInfo^.Index)
        else
           Result:=TBooleanFunc(AMethod)();
      end;
  end;
end;


Procedure GetPropInfos(TypeInfo : PTypeInfo;PropList : PPropList);
{
        Store Pointers to property information in the list pointed
        to by proplist. PRopList must contain enough space to hold ALL
        properties.
}
Var
  TD : PTypeData;
  TP : PPropInfo;
  Count : Longint;
begin
  // Get this objects TOTAL published properties count
  TD:=GetTypeData(TypeInfo);
  // Clear list
  FillChar(PropList^,TD^.PropCount*sizeof(Pointer),0);
  repeat
    TD:=GetTypeData(TypeInfo);
    // published properties count for this object
    TP:=aligntoptr(PPropInfo(aligntoptr((Pointer(@TD^.UnitName)+Length(TD^.UnitName)+1))));
    Count:=PWord(TP)^;
    // Now point TP to first propinfo record.
    Inc(Pointer(TP),SizeOF(Word));
    tp:=aligntoptr(tp);
    While Count>0 do
      begin
        // Don't overwrite properties with the same name
        if PropList^[TP^.NameIndex]=nil then
          PropList^[TP^.NameIndex]:=TP;
        // Point to TP next propinfo record.
        // Located at Name[Length(Name)+1] !
        TP:=aligntoptr(PPropInfo(pointer(@TP^.Name)+PByte(@TP^.Name)^+1));
        Dec(Count);
      end;
    TypeInfo:=TD^.Parentinfo;
  until TypeInfo=nil;
end;

Procedure InsertProp (PL : PProplist;PI : PPropInfo; Count : longint);
Var
  I : Longint;
begin
  I:=0;
  While (I<Count) and (PI^.Name>PL^[I]^.Name) do
    Inc(I);
  If I<Count then
    Move(PL^[I], PL^[I+1], (Count - I) * SizeOf(Pointer));
  PL^[I]:=PI;
end;

Procedure InsertPropnosort (PL : PProplist;PI : PPropInfo; Count : longint);
begin
  PL^[Count]:=PI;
end;

Type TInsertProp = Procedure (PL : PProplist;PI : PPropInfo; Count : longint);

//Const InsertProps : array[false..boolean] of TInsertProp = (InsertPropNoSort,InsertProp);

Function  GetPropList(TypeInfo : PTypeInfo;TypeKinds : TTypeKinds; PropList : PPropList;Sorted : boolean = true):longint;

{
  Store Pointers to property information OF A CERTAIN KIND in the list pointed
  to by proplist. PRopList must contain enough space to hold ALL
  properties.
}

Var
  TempList : PPropList;
  PropInfo : PPropinfo;
  I,Count : longint;
  DoInsertProp : TInsertProp;
begin
  if sorted then
    DoInsertProp:=@InsertProp
  else
    DoInsertProp:=@InsertPropnosort;
  Result:=0;
  Count:=GetTypeData(TypeInfo)^.Propcount;
  If Count>0 then
    begin
      GetMem(TempList,Count*SizeOf(Pointer));
      Try
        GetPropInfos(TypeInfo,TempList);
        For I:=0 to Count-1 do
          begin
            PropInfo:=TempList^[i];
            If PropInfo^.PropType^.Kind in TypeKinds then
              begin
                If (PropList<>Nil) then
                  DoInsertProp(PropList,PropInfo,Result);
                Inc(Result);
              end;
          end;
      finally
        FreeMem(TempList,Count*SizeOf(Pointer));
      end;
    end;
end;


Function GetPropList(TypeInfo: PTypeInfo; out PropList: PPropList): SizeInt;
begin
  result:=GetTypeData(TypeInfo)^.Propcount;
  if result>0 then
    begin
      getmem(PropList,result*sizeof(pointer));
      GetPropInfos(TypeInfo,PropList);
    end
  else
    PropList:=Nil;
end;

function GetPropList(AClass: TClass; out PropList: PPropList): Integer;
begin
  Result := GetPropList(PTypeInfo(AClass.ClassInfo), PropList);
end;

function GetPropList(Instance: TObject; out PropList: PPropList): Integer;
begin
  Result := GetPropList(Instance.ClassType, PropList);
end;

{ ---------------------------------------------------------------------
  Property access functions
  ---------------------------------------------------------------------}

{ ---------------------------------------------------------------------
  Ordinal properties
  ---------------------------------------------------------------------}

Function GetOrdProp(Instance : TObject;PropInfo : PPropInfo) : Int64;
type
  TGetInt64ProcIndex=function(index:longint):Int64 of object;
  TGetInt64Proc=function():Int64 of object;
  TGetIntegerProcIndex=function(index:longint):longint of object;
  TGetIntegerProc=function:longint of object;
  TGetWordProcIndex=function(index:longint):word of object;
  TGetWordProc=function:word of object;
  TGetByteProcIndex=function(index:longint):Byte of object;
  TGetByteProc=function:Byte of object;
var
  TypeInfo: PTypeInfo;
  AMethod : TMethod;
  DataSize: Integer;
  OrdType: TOrdType;
  Signed: Boolean;
begin
  Result:=0;

  TypeInfo := PropInfo^.PropType;
  Signed := false;
  DataSize := 4;
  case TypeInfo^.Kind of
{$ifdef cpu64}
    tkInterface,
    tkInterfaceRaw,
    tkDynArray,
    tkClass:
      DataSize:=8;
{$endif cpu64}
    tkChar, tkBool:
      DataSize:=1;
    tkWChar:
      DataSize:=2;
    tkSet,
    tkEnumeration,
    tkInteger:
      begin
        OrdType:=GetTypeData(TypeInfo)^.OrdType;
        case OrdType of
          otSByte,otUByte: DataSize := 1;
          otSWord,otUWord: DataSize := 2;
        end;
        Signed := OrdType in [otSByte,otSWord,otSLong];
      end;
    tkInt64 :
      begin
        DataSize:=8;
        Signed:=true;
      end;
    tkQword :
      begin
        DataSize:=8;
        Signed:=false;
      end;
  end;

  case (PropInfo^.PropProcs) and 3 of
    ptField:
      if Signed then begin
        case DataSize of
          1: Result:=PShortInt(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          2: Result:=PSmallInt(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          4: Result:=PLongint(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          8: Result:=PInt64(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
        end;
      end else begin
        case DataSize of
          1: Result:=PByte(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          2: Result:=PWord(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          4: Result:=PLongint(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          8: Result:=PInt64(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
        end;
      end;
    ptStatic,
    ptVirtual:
      begin
        if (PropInfo^.PropProcs and 3)=ptStatic then
          AMethod.Code:=PropInfo^.GetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then begin
          case DataSize of
            1: Result:=TGetByteProcIndex(AMethod)(PropInfo^.Index);
            2: Result:=TGetWordProcIndex(AMethod)(PropInfo^.Index);
            4: Result:=TGetIntegerProcIndex(AMethod)(PropInfo^.Index);
            8: result:=TGetInt64ProcIndex(AMethod)(PropInfo^.Index)
          end;
        end else begin
          case DataSize of
            1: Result:=TGetByteProc(AMethod)();
            2: Result:=TGetWordProc(AMethod)();
            4: Result:=TGetIntegerProc(AMethod)();
            8: result:=TGetInt64Proc(AMethod)();
          end;
        end;
        if Signed then begin
          case DataSize of
            1: Result:=ShortInt(Result);
            2: Result:=SmallInt(Result);
          end;
        end;
      end;
  end;
end;

Procedure SetOrdProp(Instance : TObject;PropInfo : PPropInfo;Value : Int64);
type
  TSetInt64ProcIndex=procedure(index:longint;i:Int64) of object;
  TSetInt64Proc=procedure(i:Int64) of object;
  TSetIntegerProcIndex=procedure(index,i:longint) of object;
  TSetIntegerProc=procedure(i:longint) of object;
var
  DataSize: Integer;
  AMethod : TMethod;
begin
  if PropInfo^.PropType^.Kind in [tkInt64,tkQword
  { why do we have to handle classes here, see also below? (FK) }
{$ifdef cpu64}
    ,tkInterface
    ,tkInterfaceRaw
    ,tkDynArray
    ,tkClass
{$endif cpu64}
    ] then
    DataSize := 8
  else
    DataSize := 4;
  if not(PropInfo^.PropType^.Kind in [tkInt64,tkQword,tkClass,tkInterface,tkInterfaceRaw,tkDynArray]) then
    begin
      { cut off unnecessary stuff }
      case GetTypeData(PropInfo^.PropType)^.OrdType of
        otSWord,otUWord:
          begin
            Value:=Value and $ffff;
            DataSize := 2;
          end;
        otSByte,otUByte:
          begin
            Value:=Value and $ff;
            DataSize := 1;
          end;
       end;
    end;
  case (PropInfo^.PropProcs shr 2) and 3 of
    ptField:
      case DataSize of
        1: PByte(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Byte(Value);
        2: PWord(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Word(Value);
        4: PLongint(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Longint(Value);
        8: PInt64(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
      end;
    ptStatic,
    ptVirtual:
      begin
        if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
          AMethod.Code:=PropInfo^.SetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
        AMethod.Data:=Instance;
        if datasize=8 then
          begin
            if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
              TSetInt64ProcIndex(AMethod)(PropInfo^.Index,Value)
            else
              TSetInt64Proc(AMethod)(Value);
          end
        else
          begin
            if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
              TSetIntegerProcIndex(AMethod)(PropInfo^.Index,Value)
            else
              TSetIntegerProc(AMethod)(Value);
          end;
      end;
  end;
end;


Function GetOrdProp(Instance: TObject; const PropName: string): Int64;
begin
  Result:=GetOrdProp(Instance,FindPropInfo(Instance,PropName));
end;


Procedure SetOrdProp(Instance: TObject; const PropName: string;  Value: Int64);
begin
  SetOrdProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Function GetEnumProp(Instance: TObject; Const PropInfo: PPropInfo): string;
begin
  Result:=GetEnumName(PropInfo^.PropType, GetOrdProp(Instance, PropInfo));
end;


Function GetEnumProp(Instance: TObject; const PropName: string): string;
begin
  Result:=GetEnumProp(Instance,FindPropInfo(Instance,PropName));
end;


Procedure SetEnumProp(Instance: TObject; const PropName: string;  const Value: string);
begin
  SetEnumProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Procedure SetEnumProp(Instance: TObject; Const PropInfo : PPropInfo; const Value: string);
Var
  PV : Longint;
begin
  If PropInfo<>Nil then
    begin
      PV:=GetEnumValue(PropInfo^.PropType, Value);
      if (PV<0) then
        raise EPropertyError.CreateFmt(SErrUnknownEnumValue, [Value]);
      SetOrdProp(Instance, PropInfo,PV);
    end;
end;


{ ---------------------------------------------------------------------
  Int64 wrappers
  ---------------------------------------------------------------------}

Function GetInt64Prop(Instance: TObject; PropInfo: PPropInfo): Int64;
begin
  Result:=GetOrdProp(Instance,PropInfo);
end;


procedure SetInt64Prop(Instance: TObject; PropInfo: PPropInfo; const Value: Int64);
begin
  SetOrdProp(Instance,PropInfo,Value);
end;


Function GetInt64Prop(Instance: TObject; const PropName: string): Int64;
begin
  Result:=GetInt64Prop(Instance,FindPropInfo(Instance,PropName));
end;


Procedure SetInt64Prop(Instance: TObject; const PropName: string; const Value: Int64);
begin
  SetInt64Prop(Instance,FindPropInfo(Instance,PropName),Value);
end;


{ ---------------------------------------------------------------------
  Set properties
  ---------------------------------------------------------------------}

Function GetSetProp(Instance: TObject; const PropName: string): string;
begin
  Result:=GetSetProp(Instance,PropName,False);
end;


Function GetSetProp(Instance: TObject; const PropName: string; Brackets: Boolean): string;
begin
  Result:=GetSetProp(Instance,FindPropInfo(Instance,PropName),Brackets);
end;


Function GetSetProp(Instance: TObject; const PropInfo: PPropInfo; Brackets: Boolean): string;
begin
  Result:=SetToString(PropInfo,GetOrdProp(Instance,PropInfo),Brackets);
end;


Procedure SetSetProp(Instance: TObject; const PropName: string; const Value: string);
begin
  SetSetProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Procedure SetSetProp(Instance: TObject; const PropInfo: PPropInfo; const Value: string);
begin
  SetOrdProp(Instance,PropInfo,StringToSet(PropInfo,Value));
end;

{ ---------------------------------------------------------------------
  Object properties
  ---------------------------------------------------------------------}

Function GetObjectProp(Instance: TObject; const PropName: string): TObject;
begin
  Result:=GetObjectProp(Instance,PropName,Nil);
end;


Function GetObjectProp(Instance: TObject; const PropName: string; MinClass: TClass): TObject;
begin
  Result:=GetObjectProp(Instance,FindPropInfo(Instance,PropName),MinClass);
end;


Function GetObjectProp(Instance: TObject; PropInfo : PPropInfo): TObject;
begin
  Result:=GetObjectProp(Instance,PropInfo,Nil);
end;


Function GetObjectProp(Instance: TObject; PropInfo : PPropInfo; MinClass: TClass): TObject;
begin
{$ifdef cpu64}
  Result:=TObject(GetInt64Prop(Instance,PropInfo));
{$else cpu64}
  Result:=TObject(PtrInt(GetOrdProp(Instance,PropInfo)));
{$endif cpu64}
  If (MinClass<>Nil) and (Result<>Nil) Then
    If Not Result.InheritsFrom(MinClass) then
      Result:=Nil;
end;


Procedure SetObjectProp(Instance: TObject; const PropName: string;  Value: TObject);
begin
  SetObjectProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Procedure SetObjectProp(Instance: TObject; PropInfo : PPropInfo;  Value: TObject);
begin
{$ifdef cpu64}
  SetInt64Prop(Instance,PropInfo,Int64(Value));
{$else cpu64}
  SetOrdProp(Instance,PropInfo,PtrInt(Value));
{$endif cpu64}
end;


Function GetObjectPropClass(Instance: TObject; const PropName: string): TClass;
begin
  Result:=GetTypeData(FindPropInfo(Instance,PropName,[tkClass])^.PropType)^.ClassType;
end;

Function  GetObjectPropClass(AClass: TClass; const PropName: string): TClass;
begin
  Result:=GetTypeData(FindPropInfo(AClass,PropName,[tkClass])^.PropType)^.ClassType;
end;

{ ---------------------------------------------------------------------
    Interface wrapprers
  ---------------------------------------------------------------------}


function GetInterfaceProp(Instance: TObject; const PropName: string): IInterface;

begin
  Result:=GetInterfaceProp(Instance,FindPropInfo(Instance,PropName));
end;


function GetInterfaceProp(Instance: TObject; PropInfo: PPropInfo): IInterface;
type
  TGetInterfaceProc=function:IInterface of object;
  TGetInterfaceProcIndex=function(index:longint):IInterface of object;
var
  AMethod : TMethod;
begin
  Result:=nil;
  case (PropInfo^.PropProcs) and 3 of
    ptField:
      Result:=IInterface(PPointer(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^);
    ptStatic,
    ptVirtual:
      begin
        if (PropInfo^.PropProcs and 3)=ptStatic then
          AMethod.Code:=PropInfo^.GetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
          Result:=TGetInterfaceProcIndex(AMethod)(PropInfo^.Index)
        else
          Result:=TGetInterfaceProc(AMethod)();
      end;
  end;
end;


procedure SetInterfaceProp(Instance: TObject; const PropName: string; const Value: IInterface);

begin
  SetInterfaceProp(Instance,FindPropInfo(Instance,PropName),Value);
end;

procedure SetInterfaceProp(Instance: TObject; PropInfo: PPropInfo; const Value: IInterface);
type
  TSetIntfStrProcIndex=procedure(index:longint;const i:IInterface) of object;
  TSetIntfStrProc=procedure(i:IInterface) of object;
var
  AMethod : TMethod;
begin
  case Propinfo^.PropType^.Kind of
    tkInterface:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PInterface(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetIntfStrProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetIntfStrProc(AMethod)(Value);
            end;
        end;
      end;
    tkInterfaceRaw:
      Raise Exception.Create('Cannot set RAW interface from IUnknown interface');
  end;
end;

{ ---------------------------------------------------------------------
    RAW (Corba) Interface wrapprers
  ---------------------------------------------------------------------}


function GetRawInterfaceProp(Instance: TObject; const PropName: string): Pointer;

begin
  Result:=GetRawInterfaceProp(Instance,FindPropInfo(Instance,PropName));
end;

function GetRawInterfaceProp(Instance: TObject; PropInfo: PPropInfo): Pointer;

begin
{$ifdef cpu64}
  Result:=Pointer(GetInt64Prop(Instance,PropInfo));
{$else cpu64}
  Result:=Pointer(PtrInt(GetOrdProp(Instance,PropInfo)));
{$endif cpu64}
end;

procedure SetRawInterfaceProp(Instance: TObject; const PropName: string; const Value: Pointer);

begin
  SetRawInterfaceProp(Instance,FindPropInfo(Instance,PropName),Value);
end;

procedure SetRawInterfaceProp(Instance: TObject; PropInfo: PPropInfo; const Value: Pointer);
type
  TSetPointerProcIndex=procedure(index:longint;const i:Pointer) of object;
  TSetPointerProc=procedure(i:Pointer) of object;
var
  AMethod : TMethod;
begin
  case Propinfo^.PropType^.Kind of
    tkInterfaceRaw:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PPointer(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetPointerProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetPointerProc(AMethod)(Value);
            end;
        end;
      end;
    tkInterface:
      Raise Exception.Create('Cannot set interface from RAW interface');
  end;
end;

{ ---------------------------------------------------------------------
  Dynamic array properties
  ---------------------------------------------------------------------}

function GetDynArrayProp(Instance: TObject; const PropName: string): Pointer;
begin
  Result:=GetDynArrayProp(Instance,FindPropInfo(Instance,PropName));
end;

function GetDynArrayProp(Instance: TObject; PropInfo: PPropInfo): Pointer;
type
  { we need a dynamic array as that type is usually passed differently from
    a plain pointer }
  TDynArray=array of Byte;
  TGetDynArrayProc=function:TDynArray of object;
  TGetDynArrayProcIndex=function(index:longint):TDynArray of object;
var
  AMethod : TMethod;
begin
  Result:=nil;
  if PropInfo^.PropType^.Kind<>tkDynArray then
    Exit;
  case (PropInfo^.PropProcs) and 3 of
    ptField:
      Result:=PPointer(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
    ptStatic,
    ptVirtual:
      begin
        if (PropInfo^.PropProcs and 3)=ptStatic then
          AMethod.Code:=PropInfo^.GetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
          Result:=Pointer(TGetDynArrayProcIndex(AMethod)(PropInfo^.Index))
        else
          Result:=Pointer(TGetDynArrayProc(AMethod)());
      end;
  end;
end;

procedure SetDynArrayProp(Instance: TObject; const PropName: string; const Value: Pointer);
begin
  SetDynArrayProp(Instance,FindPropInfo(Instance,PropName),Value);
end;

procedure SetDynArrayProp(Instance: TObject; PropInfo: PPropInfo; const Value: Pointer);
type
  { we need a dynamic array as that type is usually passed differently from
    a plain pointer }
  TDynArray=array of Byte;
  TSetDynArrayProcIndex=procedure(index:longint;const i:TDynArray) of object;
  TSetDynArrayProc=procedure(i:TDynArray) of object;
var
  AMethod: TMethod;
begin
  if PropInfo^.PropType^.Kind<>tkDynArray then
    Exit;
  case (PropInfo^.PropProcs shr 2) and 3 of
    ptField:
      CopyArray(PPointer(Pointer(Instance)+PtrUInt(PropInfo^.SetProc)), @Value, PropInfo^.PropType, 1);
    ptStatic,
    ptVirtual:
      begin
        if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
          AMethod.Code:=PropInfo^.SetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
          TSetDynArrayProcIndex(AMethod)(PropInfo^.Index,TDynArray(Value))
        else
          TSetDynArrayProc(AMethod)(TDynArray(Value));
      end;
  end;
end;

{ ---------------------------------------------------------------------
  String properties
  ---------------------------------------------------------------------}

Function GetStrProp(Instance: TObject; PropInfo: PPropInfo): AnsiString;
type
  TGetShortStrProcIndex=function(index:longint):ShortString of object;
  TGetShortStrProc=function():ShortString of object;
  TGetAnsiStrProcIndex=function(index:longint):AnsiString of object;
  TGetAnsiStrProc=function():AnsiString of object;
var
  AMethod : TMethod;
begin
  Result:='';
  case Propinfo^.PropType^.Kind of
    tkWString:
      Result:=AnsiString(GetWideStrProp(Instance,PropInfo));
    tkUString:
      Result := AnsiString(GetUnicodeStrProp(Instance,PropInfo));
    tkSString:
      begin
        case (PropInfo^.PropProcs) and 3 of
          ptField:
            Result := PShortString(Pointer(Instance) + LongWord(PropInfo^.GetProc))^;
          ptStatic,
          ptVirtual:
            begin
              if (PropInfo^.PropProcs and 3)=ptStatic then
                AMethod.Code:=PropInfo^.GetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                Result:=TGetShortStrProcIndex(AMethod)(PropInfo^.Index)
              else
                Result:=TGetShortStrProc(AMethod)();
            end;
        end;
      end;
    tkAString:
      begin
        case (PropInfo^.PropProcs) and 3 of
          ptField:
            Result := PAnsiString(Pointer(Instance) + LongWord(PropInfo^.GetProc))^;
          ptStatic,
          ptVirtual:
            begin
              if (PropInfo^.PropProcs and 3)=ptStatic then
                AMethod.Code:=PropInfo^.GetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                Result:=TGetAnsiStrProcIndex(AMethod)(PropInfo^.Index)
              else
                Result:=TGetAnsiStrProc(AMethod)();
            end;
        end;
      end;
  end;
end;


Procedure SetStrProp(Instance : TObject;PropInfo : PPropInfo; const Value : AnsiString);
type
  TSetShortStrProcIndex=procedure(index:longint;const s:ShortString) of object;
  TSetShortStrProc=procedure(const s:ShortString) of object;
  TSetAnsiStrProcIndex=procedure(index:longint;s:AnsiString) of object;
  TSetAnsiStrProc=procedure(s:AnsiString) of object;
var
  AMethod : TMethod;
begin
  case Propinfo^.PropType^.Kind of
    tkWString:
      SetWideStrProp(Instance,PropInfo,WideString(Value));
    tkUString:
       SetUnicodeStrProp(Instance,PropInfo,UnicodeString(Value));
    tkSString:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PShortString(Pointer(Instance) + LongWord(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetShortStrProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetShortStrProc(AMethod)(Value);
            end;
        end;
      end;
    tkAString:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PAnsiString(Pointer(Instance) + LongWord(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetAnsiStrProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetAnsiStrProc(AMethod)(Value);
            end;
        end;
      end;
  end;
end;


Function GetStrProp(Instance: TObject; const PropName: string): string;
begin
  Result:=GetStrProp(Instance,FindPropInfo(Instance,PropName));
end;


Procedure SetStrProp(Instance: TObject; const PropName: string; const Value: AnsiString);
begin
  SetStrProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Function GetWideStrProp(Instance: TObject; const PropName: string): WideString;
begin
  Result:=GetWideStrProp(Instance, FindPropInfo(Instance, PropName));
end;


procedure SetWideStrProp(Instance: TObject; const PropName: string; const Value: WideString);
begin
  SetWideStrProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Function GetWideStrProp(Instance: TObject; PropInfo: PPropInfo): WideString;
type
  TGetWideStrProcIndex=function(index:longint):WideString of object;
  TGetWideStrProc=function():WideString of object;
var
  AMethod : TMethod;
begin
  Result:='';
  case Propinfo^.PropType^.Kind of
    tkSString,tkAString:
      Result:=WideString(GetStrProp(Instance,PropInfo));
    tkUString :
      Result := GetUnicodeStrProp(Instance,PropInfo);
    tkWString:
      begin
        case (PropInfo^.PropProcs) and 3 of
          ptField:
            Result := PWideString(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          ptStatic,
          ptVirtual:
            begin
              if (PropInfo^.PropProcs and 3)=ptStatic then
                AMethod.Code:=PropInfo^.GetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                Result:=TGetWideStrProcIndex(AMethod)(PropInfo^.Index)
              else
                Result:=TGetWideStrProc(AMethod)();
            end;
        end;
      end;
  end;
end;


Procedure SetWideStrProp(Instance: TObject; PropInfo: PPropInfo; const Value: WideString);
type
  TSetWideStrProcIndex=procedure(index:longint;s:WideString) of object;
  TSetWideStrProc=procedure(s:WideString) of object;
var
  AMethod : TMethod;
begin
  case Propinfo^.PropType^.Kind of
    tkSString,tkAString:
       SetStrProp(Instance,PropInfo,AnsiString(Value));
    tkUString:
       SetUnicodeStrProp(Instance,PropInfo,Value);
    tkWString:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PWideString(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetWideStrProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetWideStrProc(AMethod)(Value);
            end;
        end;
      end;
  end;
end;

Function GetUnicodeStrProp(Instance: TObject; const PropName: string): UnicodeString;
begin
  Result:=GetUnicodeStrProp(Instance, FindPropInfo(Instance, PropName));
end;


procedure SetUnicodeStrProp(Instance: TObject; const PropName: string; const Value: UnicodeString);
begin
  SetUnicodeStrProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


Function GetUnicodeStrProp(Instance: TObject; PropInfo: PPropInfo): UnicodeString;
type
  TGetUnicodeStrProcIndex=function(index:longint):UnicodeString of object;
  TGetUnicodeStrProc=function():UnicodeString of object;
var
  AMethod : TMethod;
begin
  Result:='';
  case Propinfo^.PropType^.Kind of
    tkSString,tkAString:
      Result:=UnicodeString(GetStrProp(Instance,PropInfo));
    tkWString:
      Result:=GetWideStrProp(Instance,PropInfo);
    tkUString:
      begin
        case (PropInfo^.PropProcs) and 3 of
          ptField:
            Result := PUnicodeString(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
          ptStatic,
          ptVirtual:
            begin
              if (PropInfo^.PropProcs and 3)=ptStatic then
                AMethod.Code:=PropInfo^.GetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                Result:=TGetUnicodeStrProcIndex(AMethod)(PropInfo^.Index)
              else
                Result:=TGetUnicodeStrProc(AMethod)();
            end;
        end;
      end;
  end;
end;


Procedure SetUnicodeStrProp(Instance: TObject; PropInfo: PPropInfo; const Value: UnicodeString);
type
  TSetUnicodeStrProcIndex=procedure(index:longint;s:UnicodeString) of object;
  TSetUnicodeStrProc=procedure(s:UnicodeString) of object;
var
  AMethod : TMethod;
begin
  case Propinfo^.PropType^.Kind of
    tkSString,tkAString:
       SetStrProp(Instance,PropInfo,AnsiString(Value));
    tkWString:
       SetWideStrProp(Instance,PropInfo,Value);
    tkUString:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PUnicodeString(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetUnicodeStrProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetUnicodeStrProc(AMethod)(Value);
            end;
        end;
      end;
  end;
end;

function GetRawbyteStrProp(Instance: TObject; PropInfo: PPropInfo): RawByteString;

type
  TGetRawByteStrProcIndex=function(index:longint): RawByteString of object;
  TGetRawByteStrProc=function():RawByteString of object;
var
  AMethod : TMethod;
begin
  Result:='';
  case Propinfo^.PropType^.Kind of
    tkWString:
      Result:=RawByteString(GetWideStrProp(Instance,PropInfo));
    tkUString:
      Result:=RawByteString(GetUnicodeStrProp(Instance,PropInfo));
    tkSString:
      Result:=RawByteString(GetStrProp(Instance,PropInfo));
    tkAString:
      begin
        case (PropInfo^.PropProcs) and 3 of
          ptField:
            Result := PAnsiString(Pointer(Instance) + LongWord(PropInfo^.GetProc))^;
          ptStatic,
          ptVirtual:
            begin
              if (PropInfo^.PropProcs and 3)=ptStatic then
                AMethod.Code:=PropInfo^.GetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                Result:=TGetRawByteStrProcIndex(AMethod)(PropInfo^.Index)
              else
                Result:=TGetRawByteStrProc(AMethod)();
            end;
        end;
      end;
  end;
end;

function GetRawByteStrProp(Instance: TObject; const PropName: string): RawByteString;
begin
  Result:=GetRawByteStrProp(Instance,FindPropInfo(Instance,PropName));
end;

procedure SetRawByteStrProp(Instance: TObject; PropInfo: PPropInfo; const Value: RawByteString);

type
  TSetRawByteStrProcIndex=procedure(index:longint;s:RawByteString) of object;
  TSetRawByteStrProc=procedure(s:RawByteString) of object;
var
  AMethod : TMethod;
begin
  case Propinfo^.PropType^.Kind of
    tkWString:
      SetWideStrProp(Instance,PropInfo,WideString(Value));
    tkUString:
       SetUnicodeStrProp(Instance,PropInfo,UnicodeString(Value));
    tkSString:
      SetStrProp(Instance,PropInfo,Value); // Not 100% sure about this.
    tkAString:
      begin
        case (PropInfo^.PropProcs shr 2) and 3 of
          ptField:
            PAnsiString(Pointer(Instance) + LongWord(PropInfo^.SetProc))^:=Value;
          ptStatic,
          ptVirtual:
            begin
              if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
                AMethod.Code:=PropInfo^.SetProc
              else
                AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
              AMethod.Data:=Instance;
              if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
                TSetRawByteStrProcIndex(AMethod)(PropInfo^.Index,Value)
              else
                TSetRawByteStrProc(AMethod)(Value);
            end;
        end;
      end;
  end;
end;
procedure SetRawByteStrProp(Instance: TObject; const PropName: string; const Value: RawByteString);

begin
  SetRawByteStrProp(Instance,FindPropInfo(Instance,PropName),Value);

end;



{$ifndef FPUNONE}

{ ---------------------------------------------------------------------
  Float properties
  ---------------------------------------------------------------------}

function GetFloatProp(Instance : TObject;PropInfo : PPropInfo) : Extended;
type
  TGetExtendedProc = function:Extended of object;
  TGetExtendedProcIndex = function(Index: integer): Extended of object;
  TGetDoubleProc = function:Double of object;
  TGetDoubleProcIndex = function(Index: integer): Double of object;
  TGetSingleProc = function:Single of object;
  TGetSingleProcIndex = function(Index: integer):Single of object;
  TGetCurrencyProc = function : Currency of object;
  TGetCurrencyProcIndex = function(Index: integer) : Currency of object;
var
  AMethod : TMethod;
begin
  Result:=0.0;
  case PropInfo^.PropProcs and 3 of
    ptField:
      Case GetTypeData(PropInfo^.PropType)^.FloatType of
       ftSingle:
         Result:=PSingle(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
       ftDouble:
         Result:=PDouble(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
       ftExtended:
         Result:=PExtended(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
       ftcomp:
         Result:=PComp(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
       ftcurr:
         Result:=PCurrency(Pointer(Instance)+PtrUInt(PropInfo^.GetProc))^;
       end;
    ptStatic,
    ptVirtual:
      begin
        if (PropInfo^.PropProcs and 3)=ptStatic then
          AMethod.Code:=PropInfo^.GetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
        AMethod.Data:=Instance;
        Case GetTypeData(PropInfo^.PropType)^.FloatType of
          ftSingle:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              Result:=TGetSingleProc(AMethod)()
            else
              Result:=TGetSingleProcIndex(AMethod)(PropInfo^.Index);
          ftDouble:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              Result:=TGetDoubleProc(AMethod)()
            else
              Result:=TGetDoubleProcIndex(AMethod)(PropInfo^.Index);
          ftExtended:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              Result:=TGetExtendedProc(AMethod)()
            else
              Result:=TGetExtendedProcIndex(AMethod)(PropInfo^.Index);
          ftCurr:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              Result:=TGetCurrencyProc(AMethod)()
            else
              Result:=TGetCurrencyProcIndex(AMethod)(PropInfo^.Index);
        end;
      end;
  end;
end;


Procedure SetFloatProp(Instance : TObject;PropInfo : PPropInfo; Value : Extended);
type
  TSetExtendedProc = procedure(const AValue: Extended) of object;
  TSetExtendedProcIndex = procedure(Index: integer; AValue: Extended) of object;
  TSetDoubleProc = procedure(const AValue: Double) of object;
  TSetDoubleProcIndex = procedure(Index: integer; AValue: Double) of object;
  TSetSingleProc = procedure(const AValue: Single) of object;
  TSetSingleProcIndex = procedure(Index: integer; AValue: Single) of object;
  TSetCurrencyProc = procedure(const AValue: Currency) of object;
  TSetCurrencyProcIndex = procedure(Index: integer;  AValue: Currency) of object;
Var
  AMethod : TMethod;
begin
  case (PropInfo^.PropProcs shr 2) and 3 of
    ptfield:
      Case GetTypeData(PropInfo^.PropType)^.FloatType of
        ftSingle:
          PSingle(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
        ftDouble:
          PDouble(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
        ftExtended:
          PExtended(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
{$ifdef FPC_COMP_IS_INT64}
        ftComp:
          PComp(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=trunc(Value);
{$else FPC_COMP_IS_INT64}
        ftComp:
          PComp(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Comp(Value);
{$endif FPC_COMP_IS_INT64}
        ftCurr:
          PCurrency(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^:=Value;
       end;
    ptStatic,
    ptVirtual:
      begin
        if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
          AMethod.Code:=PropInfo^.SetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
        AMethod.Data:=Instance;
        Case GetTypeData(PropInfo^.PropType)^.FloatType of
          ftSingle:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              TSetSingleProc(AMethod)(Value)
            else
              TSetSingleProcIndex(AMethod)(PropInfo^.Index,Value);
          ftDouble:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              TSetDoubleProc(AMethod)(Value)
            else
              TSetDoubleProcIndex(AMethod)(PropInfo^.Index,Value);
          ftExtended:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              TSetExtendedProc(AMethod)(Value)
            else
              TSetExtendedProcIndex(AMethod)(PropInfo^.Index,Value);
          ftCurr:
            if ((PropInfo^.PropProcs shr 6) and 1)=0 then
              TSetCurrencyProc(AMethod)(Value)
            else
              TSetCurrencyProcIndex(AMethod)(PropInfo^.Index,Value);
        end;
      end;
  end;
end;


function GetFloatProp(Instance: TObject; const PropName: string): Extended;
begin
  Result:=GetFloatProp(Instance,FindPropInfo(Instance,PropName))
end;


Procedure SetFloatProp(Instance: TObject; const PropName: string;  Value: Extended);
begin
  SetFloatProp(Instance,FindPropInfo(Instance,PropName),Value);
end;

{$endif}

{ ---------------------------------------------------------------------
  Method properties
  ---------------------------------------------------------------------}


Function GetMethodProp(Instance : TObject;PropInfo : PPropInfo) : TMethod;
type
  TGetMethodProcIndex=function(Index: Longint): TMethod of object;
  TGetMethodProc=function(): TMethod of object;
var
  value: PMethod;
  AMethod : TMethod;
begin
  Result.Code:=nil;
  Result.Data:=nil;
  case (PropInfo^.PropProcs) and 3 of
    ptField:
      begin
        Value:=PMethod(Pointer(Instance)+PtrUInt(PropInfo^.GetProc));
        if Value<>nil then
          Result:=Value^;
      end;
    ptStatic,
    ptVirtual:
      begin
        if (PropInfo^.PropProcs and 3)=ptStatic then
          AMethod.Code:=PropInfo^.GetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.GetProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
          Result:=TGetMethodProcIndex(AMethod)(PropInfo^.Index)
        else
          Result:=TGetMethodProc(AMethod)();
      end;
  end;
end;


Procedure SetMethodProp(Instance : TObject;PropInfo : PPropInfo; const Value : TMethod);
type
  TSetMethodProcIndex=procedure(index:longint;p:TMethod) of object;
  TSetMethodProc=procedure(p:TMethod) of object;
var
  AMethod : TMethod;
begin
  case (PropInfo^.PropProcs shr 2) and 3 of
    ptField:
      PMethod(Pointer(Instance)+PtrUInt(PropInfo^.SetProc))^ := Value;
    ptStatic,
    ptVirtual:
      begin
        if ((PropInfo^.PropProcs shr 2) and 3)=ptStatic then
          AMethod.Code:=PropInfo^.SetProc
        else
          AMethod.Code:=PCodePointer(Pointer(Instance.ClassType)+PtrUInt(PropInfo^.SetProc))^;
        AMethod.Data:=Instance;
        if ((PropInfo^.PropProcs shr 6) and 1)<>0 then
          TSetMethodProcIndex(AMethod)(PropInfo^.Index,Value)
        else
          TSetMethodProc(AMethod)(Value);
      end;
  end;
end;


Function GetMethodProp(Instance: TObject; const PropName: string): TMethod;
begin
  Result:=GetMethodProp(Instance,FindPropInfo(Instance,PropName));
end;


Procedure SetMethodProp(Instance: TObject; const PropName: string;  const Value: TMethod);
begin
  SetMethodProp(Instance,FindPropInfo(Instance,PropName),Value);
end;


{ ---------------------------------------------------------------------
  Variant properties
  ---------------------------------------------------------------------}

Procedure CheckVariantEvent(P : CodePointer);

begin
  If (P=Nil) then
    Raise Exception.Create(SErrNoVariantSupport);
end;

Function GetVariantProp(Instance : TObject;PropInfo : PPropInfo): Variant;
begin
  CheckVariantEvent(CodePointer(OnGetVariantProp));
  Result:=OnGetVariantProp(Instance,PropInfo);
end;


Procedure SetVariantProp(Instance : TObject;PropInfo : PPropInfo; const Value: Variant);
begin
   CheckVariantEvent(CodePointer(OnSetVariantProp));
   OnSetVariantProp(Instance,PropInfo,Value);
end;


Function GetVariantProp(Instance: TObject; const PropName: string): Variant;
begin
  Result:=GetVariantProp(Instance,FindPropInfo(Instance,PropName));
end;


Procedure SetVariantProp(Instance: TObject; const PropName: string;  const Value: Variant);
begin
  SetVariantprop(instance,FindpropInfo(Instance,PropName),Value);
end;


{ ---------------------------------------------------------------------
  All properties through variant.
  ---------------------------------------------------------------------}

Function GetPropValue(Instance: TObject; const PropName: string): Variant;
begin
  Result := GetPropValue(Instance,FindPropInfo(Instance, PropName));
end;

Function GetPropValue(Instance: TObject; const PropName: string; PreferStrings: Boolean): Variant;

begin
  Result := GetPropValue(Instance,FindPropInfo(Instance, PropName),PreferStrings);
end;

Function GetPropValue(Instance: TObject; PropInfo: PPropInfo): Variant;
begin
  Result := GetPropValue(Instance, PropInfo, True);
end;

Function GetPropValue(Instance: TObject; PropInfo: PPropInfo; PreferStrings: Boolean): Variant;

begin
  CheckVariantEvent(CodePointer(OnGetPropValue));
  Result:=OnGetPropValue(Instance,PropInfo,PreferStrings);
end;

Procedure SetPropValue(Instance: TObject; const PropName: string;  const Value: Variant);

begin
  SetPropValue(Instance, FindPropInfo(Instance, PropName), Value);
end;

Procedure SetPropValue(Instance: TObject; PropInfo: PPropInfo;  const Value: Variant);

begin
  CheckVariantEvent(CodePointer(OnSetPropValue));
  OnSetPropValue(Instance,PropInfo,Value);
end;


{ ---------------------------------------------------------------------
  Easy access methods that appeared in Delphi 5
  ---------------------------------------------------------------------}

Function IsPublishedProp(Instance: TObject; const PropName: string): Boolean;
begin
  Result:=GetPropInfo(Instance,PropName)<>Nil;
end;

Function IsPublishedProp(AClass: TClass; const PropName: string): Boolean;
begin
  Result:=GetPropInfo(AClass,PropName)<>Nil;
end;

Function PropIsType(Instance: TObject; const PropName: string; TypeKind: TTypeKind): Boolean;
begin
  Result:=PropType(Instance,PropName)=TypeKind
end;

Function PropIsType(AClass: TClass; const PropName: string; TypeKind: TTypeKind): Boolean;
begin
  Result:=PropType(AClass,PropName)=TypeKind
end;

Function PropType(Instance: TObject; const PropName: string): TTypeKind;
begin
  Result:=FindPropInfo(Instance,PropName)^.PropType^.Kind;
end;

Function PropType(AClass: TClass; const PropName: string): TTypeKind;
begin
  Result:=FindPropInfo(AClass,PropName)^.PropType^.Kind;
end;

Function IsStoredProp(Instance: TObject; const PropName: string): Boolean;
begin
  Result:=IsStoredProp(instance,FindPropInfo(Instance,PropName));
end;

{ TParameterLocation }

function TParameterLocation.GetReference: Boolean;
begin
  Result := (LocType and $80) <> 0;
end;

function TParameterLocation.GetRegType: TRegisterType;
begin
  Result := TRegisterType(LocType and $7F);
end;

function TParameterLocation.GetShiftVal: Int8;
begin
  if GetReference then begin
    if Offset < Low(Int8) then
      Result := Low(Int8)
    else if Offset > High(Int8) then
      Result := High(Int8)
    else
      Result := Offset;
  end else
    Result := 0;
end;

{ TParameterLocations }

function TParameterLocations.GetLocation(aIndex: Byte): PParameterLocation;
begin
  if aIndex >= Count then
    Result := Nil
  else
    Result := PParameterLocation(PByte(aligntoptr(PByte(@Count) + SizeOf(Count))) + SizeOf(TParameterLocation) * aIndex);
end;

function TParameterLocations.GetTail: Pointer;
begin
  Result := PByte(aligntoptr(PByte(@Count) + SizeOf(Count))) + SizeOf(TParameterLocation) * Count;
end;

{ TProcedureParam }

function TProcedureParam.GetParamType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(ParamTypeRef);
end;

function TProcedureParam.GetFlags: Byte;
begin
  Result := PByte(@ParamFlags)^;
end;

{ TManagedField }

function TManagedField.GetTypeRef: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(TypeRefRef);
end;

{ TArrayTypeData }

function TArrayTypeData.GetElType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(ElTypeRef);
end;

function TArrayTypeData.GetDims(aIndex: Byte): PTypeInfo;
begin
  Result := DerefTypeInfoPtr(DimsRef[aIndex]);
end;

{ TProcedureSignature }

function TProcedureSignature.GetResultType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(ResultTypeRef);
end;

function TProcedureSignature.GetParam(ParamIndex: Integer): PProcedureParam;
begin
  if (ParamIndex<0)or(ParamIndex>=ParamCount) then
    Exit(nil);
  Result := PProcedureParam(PByte(@Flags) + SizeOf(Self));
  while ParamIndex > 0 do
    begin
      Result := PProcedureParam(aligntoptr((PByte(@Result^.Name) + (Length(Result^.Name) + 1) * SizeOf(AnsiChar))));
      dec(ParamIndex);
    end;
end;

{ TVmtMethodParam }

function TVmtMethodParam.GetParaLocs: PParameterLocations;
begin
  Result := PParameterLocations(aligntoptr(PByte(@Name[0]) + Length(Name) + Sizeof(Name[0])));
end;

function TVmtMethodParam.GetTail: Pointer;
begin
  Result := ParaLocs^.Tail;
end;

function TVmtMethodParam.GetNext: PVmtMethodParam;
begin
  Result := PVmtMethodParam(aligntoptr(Tail));
end;

{ TIntfMethodEntry }

function TIntfMethodEntry.GetParam(Index: Word): PVmtMethodParam;
begin
  if Index >= ParamCount then
    Result := Nil
  else
    begin
      Result := PVmtMethodParam(aligntoptr(PByte(@Name[0]) + SizeOf(Name[0]) + Length(Name)));
      while Index > 0 do
        begin
          Result := Result^.Next;
          Dec(Index);
        end;
    end;
end;

function TIntfMethodEntry.GetResultLocs: PParameterLocations;
begin
  if not Assigned(ResultType) then
    Result := Nil
  else if ParamCount = 0 then
    Result := PParameterLocations(aligntoptr(PByte(@Name[0]) + SizeOf(Name[0]) + Length(Name)))
  else
    Result := PParameterLocations(aligntoptr(Param[ParamCount - 1]^.Tail));
end;

function TIntfMethodEntry.GetTail: Pointer;
var
  retloc: PParameterLocations;
begin
  if Assigned(ResultType) then
    begin
      retloc := ResultLocs;
      Result := PByte(@retloc^.Count) + SizeOf(retloc^.Count) + SizeOf(TParameterLocation) * retloc^.Count;
    end
  else if ParamCount = 0 then
    Result := PByte(@Name[0]) + Length(Name) + SizeOf(Byte)
  else
    Result := Param[ParamCount - 1]^.Tail;
end;

function TIntfMethodEntry.GetNext: PIntfMethodEntry;
begin
  Result := PIntfMethodEntry(aligntoptr(Tail));
end;

{ TIntfMethodTable }

function TIntfMethodTable.GetMethod(Index: Word): PIntfMethodEntry;
begin
  if (RTTICount = $FFFF) or (Index >= RTTICount) then
    Result := Nil
  else
    begin
      Result := aligntoptr(PIntfMethodEntry(PByte(@RTTICount) + SizeOf(RTTICount)));
      while Index > 0 do
        begin
          Result := Result^.Next;
          Dec(Index);
        end;
    end;
end;

{ TInterfaceData }

function TInterfaceData.GetUnitName: ShortString;
begin
  Result := UnitNameField;
end;

function TInterfaceData.GetPropertyTable: PPropData;
var
  p: PByte;
begin
  p := PByte(@UnitNameField[0]) + SizeOf(UnitNameField[0]) + Length(UnitNameField);
  Result := AlignTypeData(p);
end;

function TInterfaceData.GetMethodTable: PIntfMethodTable;
begin
  Result := aligntoptr(PropertyTable^.Tail);
end;

{ TInterfaceRawData }

function TInterfaceRawData.GetUnitName: ShortString;
begin
  Result := UnitNameField;
end;

function TInterfaceRawData.GetIIDStr: ShortString;
begin
  Result := PShortString(AlignTypeData(PByte(@UnitNameField[0]) + SizeOf(UnitNameField[0]) + Length(UnitNameField)))^;
end;

function TInterfaceRawData.GetPropertyTable: PPropData;
var
  p: PByte;
begin
  p := AlignTypeData(PByte(@UnitNameField[0]) + SizeOf(UnitNameField[0]) + Length(UnitNameField));
  p := p + SizeOf(p^) + p^;
  Result := aligntoptr(p);
end;

function TInterfaceRawData.GetMethodTable: PIntfMethodTable;
begin
  Result := aligntoptr(PropertyTable^.Tail);
end;

{ TClassData }

function TClassData.GetUnitName: ShortString;
begin
  Result := UnitNameField;
end;

function TClassData.GetPropertyTable: PPropData;
var
  p: PByte;
begin
  p := PByte(@UnitNameField[0]) + SizeOf(UnitNameField[0]) + Length(UnitNameField);
  Result := AlignTypeData(p);
end;

{ TTypeData }

function TTypeData.GetBaseType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(BaseTypeRef);
end;

function TTypeData.GetCompType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(CompTypeRef);
end;

function TTypeData.GetParentInfo: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(ParentInfoRef);
end;

{$ifndef VER3_0}
function TTypeData.GetRecInitData: PRecInitData;
begin
  Result := PRecInitData(aligntoptr(PTypeData(RecInitInfo+2+PByte(RecInitInfo+1)^)));
end;
{$endif}

function TTypeData.GetHelperParent: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(HelperParentRef);
end;

function TTypeData.GetExtendedInfo: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(ExtendedInfoRef);
end;

function TTypeData.GetIntfParent: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(IntfParentRef);
end;

function TTypeData.GetRawIntfParent: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(RawIntfParentRef);
end;

function TTypeData.GetIIDStr: ShortString;
begin
  Result := PShortString(AlignTypeData(Pointer(@RawIntfUnit) + Length(RawIntfUnit) + 1))^;
end;

function TTypeData.GetElType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(elTypeRef);
end;

function TTypeData.GetElType2: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(elType2Ref);
end;

function TTypeData.GetInstanceType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(InstanceTypeRef);
end;

function TTypeData.GetRefType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(RefTypeRef);
end;

{ TPropData }

function TPropData.GetProp(Index: Word): PPropInfo;
begin
  if Index >= PropCount then
    Result := Nil
  else
    begin
      Result := PPropInfo(aligntoptr(PByte(@PropCount) + SizeOf(PropCount)));
      while Index > 0 do
        begin
          Result := aligntoptr(Result^.Tail);
          Dec(Index);
        end;
    end;
end;

function TPropData.GetTail: Pointer;
begin
  if PropCount = 0 then
    Result := PByte(@PropCount) + SizeOf(PropCount)
  else
    Result := Prop[PropCount - 1]^.Tail;
end;

{ TPropInfo }

function TPropInfo.GetPropType: PTypeInfo;
begin
  Result := DerefTypeInfoPtr(PropTypeRef);
end;

function TPropInfo.GetTail: Pointer;
begin
  Result := PByte(@Name[0]) + SizeOf(Name[0]) + Length(Name);
end;

function TPropInfo.GetNext: PPropInfo;
begin
  Result := PPropInfo(aligntoptr(Tail));
end;

type
  TElementAlias = record
    Ordinal : Integer;
    Alias : string;
  end;
  TElementAliasArray = Array of TElementAlias;
  PElementAliasArray = ^TElementAliasArray;

  TEnumeratedAliases = record
    TypeInfo: PTypeInfo;
    Aliases: TElementAliasArray;
  end;
  TEnumeratedAliasesArray = Array of TEnumeratedAliases;

Var
  EnumeratedAliases : TEnumeratedAliasesArray;

Function IndexOfEnumeratedAliases(aTypeInfo : PTypeInfo) : integer;

begin
  Result:=Length(EnumeratedAliases)-1;
  while (Result>=0) and (EnumeratedAliases[Result].TypeInfo<>aTypeInfo) do
    Dec(Result);
end;

Function GetEnumeratedAliases(aTypeInfo : PTypeInfo) : PElementAliasArray;

Var
  I : integer;

begin
  I:=IndexOfEnumeratedAliases(aTypeInfo);
  if I=-1 then
    Result:=Nil
  else
    Result:=@EnumeratedAliases[i].Aliases
end;

Function AddEnumeratedAliases(aTypeInfo : PTypeInfo) : PElementAliasArray;

Var
  L : Integer;

begin
  L:=Length(EnumeratedAliases);
  SetLength(EnumeratedAliases,L+1);
  EnumeratedAliases[L].TypeInfo:=aTypeInfo;
  Result:=@EnumeratedAliases[L].Aliases;
end;

procedure RemoveEnumElementAliases(aTypeInfo: PTypeInfo);

Var
  I,L : integer;
  A : TEnumeratedAliases;

begin
  I:=IndexOfEnumeratedAliases(aTypeInfo);
  if I=-1 then
    exit;
  A:=EnumeratedAliases[i];
  A.Aliases:=Nil;
  A.TypeInfo:=Nil;
  L:=Length(EnumeratedAliases)-1;
  EnumeratedAliases[i]:=EnumeratedAliases[L];
  EnumeratedAliases[L]:=A;
  SetLength(EnumeratedAliases,L);
end;

Resourcestring
  SErrNotAnEnumerated = 'Type information points to non-enumerated type';
  SErrInvalidEnumeratedCount = 'Invalid number of enumerated values';
  SErrDuplicateEnumerated = 'Duplicate alias for enumerated value';

procedure AddEnumElementAliases(aTypeInfo: PTypeInfo; const aNames: array of string; aStartValue: Integer = 0);

var
  Aliases: PElementAliasArray;
  A : TElementAliasArray;
  L, I, J : Integer;
  N : String;
  PT : PTypeData;


begin
  if (aTypeInfo^.Kind<>tkEnumeration) then
    raise EArgumentException.Create(SErrNotAnEnumerated);
  PT:=GetTypeData(aTypeInfo);
  if (High(aNames)=-1) or ((aStartValue+High(aNames))> PT^.MaxValue) then
    raise EArgumentException.Create(SErrInvalidEnumeratedCount);
  Aliases:=GetEnumeratedAliases(aTypeInfo);
  if (Aliases=Nil) then
    Aliases:=AddEnumeratedAliases(aTypeInfo);
  A:=Aliases^;
  I:=0;
  L:=Length(a);
  SetLength(a,L+High(aNames)+1);
  try
    for N in aNames do
      begin
      for J:=0 to (L+I)-1 do
        if SameText(N,A[J].Alias) then
          raise EArgumentException.Create(SErrDuplicateEnumerated);
      with A[L+I] do
        begin
        Ordinal:=aStartValue+I;
        alias:=N;
        end;
      Inc(I);
      end;
  finally
    // In case of exception, we need to correct the length.
    if Length(A)<>I+L then
      SetLength(A,I+L);
    Aliases^:=A;
  end;
end;

function GetEnumeratedAliasValue(aTypeInfo: PTypeInfo; const aName: string): Integer;

var
  I : Integer;
  Aliases: PElementAliasArray;

begin
  Result:=-1;
  Aliases:=GetEnumeratedAliases(aTypeInfo);
  if (Aliases=Nil) then
    Exit;
  I:=Length(Aliases^)-1;
  While (Result=-1) and (I>=0) do
    begin
    if SameText(Aliases^[I].Alias, aName) then
      Result:=Aliases^[I].Ordinal;
    Dec(I);
    end;
end;


end.
