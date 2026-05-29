unit RandyGaul.qu3e;

// Lightweight and Simple 3D Open Source Physics Engine in Delphi

// Based on Qu3e by Randy Gaul <https://github.com/RandyGaul/qu3e>

// (c)2026 Execute SARL https://www.execute.fr

interface
{$POINTERMATH ON}
uses
  System.Math,
  System.Math.Vectors;  // todo

// common/q3Types.h

type
  r32 = Single;
  r64 = Double;
  f32 = Single;
  f64 = Double;
  i8 = ShortInt;
  i16 = SmallInt;
  i32 = Integer;
  u8 = Byte;
  u16 = Word;
  u32 = Cardinal;

  pu8 = ^u8;
  pi32 = ^i32;
  pr32 = ^r32;

const
// math/q3Math.h

  Q3_R32_MAX = 340282346638528859811704183484516925440.0;

// common/q3Settings.h

  Q3_SLEEP_LINEAR = 0.01;
  Q3_SLEEP_ANGULAR = (3.0 / 180.0) * PI;
  Q3_SLEEP_TIME = 0.5;
  Q3_BAUMGARTE = 0.2;
  Q3_PENETRATION_SLOP = 0.05;

type

// PagedAllocator

  TSlotPage<T> = class;

  TSlot<T> = record
  private
    Data: T;
    Next: ^TSlot<T>;
    Page: TSlotPage<T>;
  end;

  TSlotPage<T> = class
  const
    SLOT_COUNT = 256;
  private
    FSlots: array[0..SLOT_COUNT - 1] of TSlot<T>;
    FFreeSlot: ^TSlot<T>;
    FNextPage: TSlotPage<T>;
    FNextFree: TSlotPage<T>;
  public
    constructor Create;
  end;

  TPagedAllocator<T> = class
  private
    FFirstPage: TSlotPage<T>;
    FFirstFree : TSlotPage<T>;
    function AllocatePtr: Pointer;    //  \__ wrong H2219
    procedure ReleasePtr(P: Pointer); //  /
   public
    destructor Destroy; override;
    procedure Clear;
  end;

// math/q3Vec3.h

  q3Vec3 = record
    class function Create(_x, _y, _z: r32): q3Vec3; inline; static;
    procedure SetXYZ(_x, _y, _z: r32); inline;
    procedure SetAll(a: r32); inline;
    procedure Identity; inline;
    function Dot(const v: q3Vec3): r32; inline;
    function Cross(const v: q3Vec3): q3Vec3; inline;
    function Length: r32;
    function Normalize: q3Vec3;
    function Abs: q3Vec3;
    function Min(const v: q3Vec3): q3Vec3;
    function Max(const v: q3Vec3): q3Vec3;
    procedure ComputeBasis(var b, c: q3Vec3);
    class operator Add(const a, b: q3Vec3): q3Vec3; inline;
    class operator Subtract(const a, b: q3Vec3): q3Vec3; inline;
    class operator Multiply(const a, b: q3Vec3): q3Vec3; inline;
    class operator Multiply(const v: q3Vec3; const f: Single): q3Vec3; inline;
    class operator Divide(const v: q3Vec3; const f: Single): q3Vec3;
    class operator Negative(const v: q3Vec3): q3Vec3;
  case Byte of
    0: (v: array[0..2] of r32);
    1: (x, y, z: r32);
  end;
  PQ3Vec3 = ^q3Vec3;

// math/q3Mat3.h

  q3Mat3 = record
    v: array[0..2] of q3Vec3;
    constructor Create(a, b, c, d, e, f, g, h, i: r32); overload;
    procedure SetRows(const _x, _y, _z: q3Vec3);
    constructor Create(const axis: q3Vec3; angle: r32); overload; // Set
    procedure Identity;
    function Transpose: q3Mat3;
    function Inverse: q3Mat3;
    class function Diagonal1(a: r32): q3Mat3; static; inline;
    class function Diagonal3(a, b, c: r32): q3Mat3; static; inline;
    class operator Add(const m1, m2: q3Mat3): q3Mat3;
    class operator Subtract(const m1, m2: q3Mat3): q3Mat3;
    class operator Multiply(const m: q3Mat3; f: r32): q3Mat3; inline;
    class operator Multiply(const m: q3Mat3; const rhs: q3Vec3): q3Vec3; inline;
    class operator Multiply(const m, rhs: q3Mat3): q3Mat3;
    function Column0: q3Vec3;
    function Column1: q3Vec3;
    function Column2: q3Vec3;
    property ex: q3Vec3 read v[0] write v[0];
    property ey: q3Vec3 read v[1] write v[1];
    property ez: q3Vec3 read v[2] write v[2];
  end;

// math/q3Mat3.inl

  q3Vec3Helper = record helper for q3Vec3
    function OuterProduct(const v: q3Vec3): q3Mat3;
  end;

// math/q3Quaternion.h

  q3Quaternion = record
    v: array[0..3] of r32;
    constructor Create(a, b, c, d: r32); overload;
    constructor Create(const axis: q3Vec3; radians: r32); overload;
    procedure ToAxisAngle(var axis: q3Vec3; var angle: r32);
    procedure Integrate(const dv: q3Vec3; dt: r32);
    procedure Normalize;
    function ToMat3: q3Mat3;
    class operator Multiply(const a, b: q3Quaternion): q3Quaternion; inline;
    property x: r32 read v[0] write v[0];
    property y: r32 read v[1] write v[1];
    property z: r32 read v[2] write v[2];
    property w: r32 read v[3] write v[3];
  end;

// common/q3Geometry.h

  q3AABB = record
    min: q3Vec3;
    max: q3Vec3;
    function Contains(const other: q3AABB): Boolean; overload; inline;
    function Contains(const point: q3Vec3): Boolean; overload; inline;
    function SurfaceArea: r32; inline;
    function Combine(const q: q3AABB): q3AABB; inline;
    function AABBtoAABB(const q: q3AABB): Boolean; inline;
  end;
  pq3AABB = ^q3AABB;

  q3RaycastData = record
    start: q3Vec3;    // Beginning point of the ray
    dir: q3Vec3;      // Direction of the ray (normalized)
    t: r32;           // Time specifying ray endpoint

    toi: r32;         // Solved time of impact
    normal: q3Vec3;   // Surface normal at impact

    constructor Create(const startPoint, direction: q3Vec3; endPointTime: r32);
    // Uses toi, start and dir to compute the point at toi. Should
    // only be called after a raycast has been conducted with a
    // return value of true.
    function GetImpactPoint: q3Vec3; inline;
  end;
  pq3RaycastData = ^q3RaycastData;

// math/q3Transform.h

  q3Transform = record
    position: q3Vec3;
    rotation: q3Mat3;
    procedure Identity; inline;
  end;

// broadphase/q3DynamicAABBTree.h

  q3Render = class
    procedure SetPenColor(r, g, b: f32; a: f32 = 1.0); virtual; abstract;
    procedure SetPenPosition(x, y, z: f32); virtual; abstract;
    procedure SetScale(sx, sy, sz: f32); virtual; abstract;

    procedure MoveTo(const v: q3Vec3); virtual; abstract;
    procedure LineTo(const v: q3Vec3); virtual; abstract;
    procedure Line(x, y, z: f32); virtual; abstract;

    procedure DrawCube(const tx: q3Transform; const e: q3Vec3); virtual; abstract;

    procedure Point; virtual; abstract;

    procedure SetAwake(awake: Boolean); virtual; abstract;
  end;

  q3CallBack = function(id: i32): Boolean of object;

  q3DynamicAABBTree = class
  private
    type
      Node = record
      const
        Null = -1;
      var
        // Fat AABB for leafs, bounding AABB for branches
        aabb: q3AABB;
        parent: i32;
        // Child indices
        left: i32;
        right: i32;
        userData: Pointer;
        // leaf = 0, free nodes = -1
        height: i32;
        function IsLeaf: Boolean;
        property next: i32 read parent write parent; // union (free list)
      end;
      pNode = ^Node;
  private
    m_root: i32;
    m_nodes: TArray<Node>;
    m_count: i32;       // Number of active nodes
    m_capacity: i32;    // Max capacity of nodes
    m_freeList: i32;
    function AllocateNode: i32;
    procedure DeallocateNode(index: i32);
    function Balance(iA: i32): i32;
    procedure InsertLeaf(id: i32);
    procedure RemoveLeaf(id: i32);
    procedure ValidateStructure(index: i32);
    procedure RenderNode(render: q3Render; index: i32);
    // Correct AABB hierarchy heights and AABBs starting at supplied
	  // index traversing up the heirarchy
    procedure SyncHeirarchy(index: i32);
    // Insert nodes at a given index until m_capacity into the free list
    procedure AddToFreeList(index: i32);
  public
    constructor Create;
    function Insert(const aabb: q3AABB; userData: Pointer): i32;
    procedure Remove(id: i32);
    function Update(id: i32; const aabb: q3AABB): Boolean;

    function GetUserData(id: i32): Pointer; inline;
    function GetFatAABB(id: i32): q3AABB; inline;
    procedure Render(render: q3Render);
    procedure Query(cb: q3CallBack; const aabb: q3AABB); overload;
    procedure Query(cb: q3CallBack; const rayCast: q3RaycastData); overload;
    procedure Validate();
  end;

// broadphase/q3BroadPhase.h

   q3ContactManager = class;
   pq3Box = ^q3Box;

   q3ContactPair = record
     A: i32;
     B: i32;
   end;
   pq3ContactPair = ^q3ContactPair;

   q3BroadPhase = class
   private
     m_manager: q3ContactManager;
     m_pairBuffer: TArray<q3ContactPair>;
     m_pairCount: i32;
     m_pairCapacity: i32;
     m_moveBuffer: TArray<i32>;
     m_moveCount: i32;
     m_moveCapacity: i32;
     m_tree: q3DynamicAABBTree;
     m_currentIndex: i32;
     procedure BufferMove(id: i32);
     function TreeCallBack(index: i32): Boolean;
   public
     constructor Create(manager: q3ContactManager);
     destructor Destroy; override;
     procedure InsertBox(box: pq3Box; const aabb: q3AABB);
     procedure RemoveBox(box: pq3Box);
     // Generates the contact list. All previous contacts are returned to the allocator
     // before generation occurs.
     procedure UpdatePairs();
     procedure Update(id: i32; const aabb: q3AABB);
     function TestOverlap(A, B: i32): Boolean; inline;
   end;

// dynmaics/q3Contact.h

   q3FeaturePair = record
   case Byte of // union
     0: (
       inR: u8;
       outR: u8;
       inI: u8;
       outI: u8;
     );
     1: (key: i32);
   end;

   q3Contact = record
     position: q3Vec3;
     penetration: r32;
     normalImpulse: r32;
     tangentImpulse: array[0..1] of r32;
     bias: r32;
     normalMass: r32;
     tangentMass: array[0..1] of r32;
     fp: q3FeaturePair;
     warmStarted: u8;
   end;
   pq3Contact = ^q3Contact;

   pq3Manifold = ^q3Manifold;
   q3Manifold = record
     A: pq3Box;
     B: pq3Box;
     normal: q3Vec3;
     tangentVectors: array[0..1] of q3Vec3;
     contacts: array[0..7] of q3Contact;
     contactCount: i32;
     next: pq3Manifold;
     prev: pq3Manifold;
     sensor: Boolean;
     procedure SetPair(a, b: pq3Box);
   end;

   pq3Body = ^q3Body;
   ppq3Body = ^pq3Body;
   pq3ContactConstraint = ^q3ContactConstraint;
   ppq3ContactConstraint = ^pq3ContactConstraint;

   pq3ContactEdge = ^q3ContactEdge;
   q3ContactEdge = record
     other: pq3Body;
     constraint: pq3ContactConstraint;
     next: pq3ContactEdge;
     prev: pq3ContactEdge;
   end;

   q3ContactConstraint = record
   const
     eColliding = 1;
     eWasColliding = 2;
     eIsland = 4;
   public
     A, B: pq3Box;
     bodyA, bodyB: pq3Body;
     edgeA: q3ContactEdge;
     edgeB: q3ContactEdge;
     prev: pq3ContactConstraint;
     next: pq3ContactConstraint;
     friction: r32;
     restitution: r32;
     manifold: q3Manifold;
     m_flags: i32;
     procedure SolveCollision;
   end;

// dynamics/q3ContactManager.h

   q3ContactListener = class
     procedure BeginContact(contact: pq3ContactConstraint); virtual; abstract;
     procedure EndContact(contact: pq3ContactConstraint); virtual; abstract;
   end;

   TContactConstraintAllocator = class;

   q3ContactManager = class
   private
     m_contactList: pq3ContactConstraint;
     m_contactCount: i32;
     m_allocator: TContactConstraintAllocator;
     m_broadphase: q3BroadPhase;
     m_contactListener: q3ContactListener;
   public
     constructor Create;
     destructor Destroy; override;
     procedure AddContact(A, B: pq3Box);
     procedure FindNewContacts;
     procedure RemoveContact( contact: pq3ContactConstraint );
     procedure RemoveContactsFromBody(body: pq3Body);
     procedure RemoveFromBroadphase( body: pq3Body );
     procedure TestCollisions;
//     procedure SolveCollision(param: Pointer);  ???
     procedure RenderContacts(render: q3Render);
   end;

  q3BodyType = (
  	eStaticBody,
	  eDynamicBody,
	  eKinematicBody
  );

  q3BodyDef = record
    axis: q3Vec3;
    angle: r32;
    position: q3Vec3;
    linearVelocity: q3Vec3;
    angularVelocity: q3Vec3;
    gravityScale: r32;
    layers: i32;
    userData: Pointer;
    linearDamping: r32;
    angularDamping: r32;
    bodyType: q3BodyType;
    padding: array[0..2] of Byte;
    allowSleep: Boolean;
    awake: Boolean;
    active: Boolean;
    lockAxisX: Boolean;
    lockAxisY: Boolean;
    lockAxisZ: Boolean;
    class operator Initialize(out def: q3BodyDef);
  end;
  pq3BodyDef = ^q3BodyDef;

// dynamics/q3ContactSolver.h

  q3ContactState = record
    ra: q3Vec3;
    rb: q3Vec3;
    penetration: r32;
    normalImpulse: r32;
    tangentImpulse: array[0..1] of r32;
    bias: r32;
    normalMass: r32;
    tangentMass: array[0..1] of r32;
  end;
  pq3ContactState = ^q3ContactState;

  q3ContactConstraintState = record
    contacts: array[0..7] of q3ContactState;
    contactCount: i32;
    tangentVectors: array[0..1] of q3Vec3;
    normal: q3Vec3;
    centerA: q3Vec3;
    centerB: q3Vec3;
    iA: q3Mat3;
    iB: q3Mat3;
    mA: r32;
    mB: r32;
    restitution: r32;
    friction: r32;
    indexA: i32;
    indexB: i32;
  end;
  pq3ContactConstraintState = ^q3ContactConstraintState;

// dynamics/q3Island.h

  q3VelocityState = record
    w: q3Vec3;
    v: q3Vec3;
  end;
  pq3VelocityState = ^q3VelocityState;

  pq3Island = ^q3Island;
  q3Island = record
    m_bodies: TArray<pq3Body>;
    m_velocities: TArray<q3VelocityState>;
    m_bodyCapacity: i32;
    m_bodyCount: i32;
    m_contacts: TArray<pq3ContactConstraint>;
    m_contactStates: TArray<q3ContactConstraintState>;
    m_contactCount: i32;
    m_contactCapacity: i32;
    m_dt: r32;
    m_gravity: q3Vec3;
    m_iterations: i32;
    m_allowSleep: Boolean;
    m_enableFriction: Boolean;
    procedure SetBodyCount(count: i32);
    procedure SetContactCount(count: i32);
    procedure Clear;
    procedure Solve;
    procedure Add(body: pq3Body); overload;
    procedure Add(contact: pq3ContactConstraint); overload;
    procedure Initialize;
  end;

// scene/q3Scene.h

  q3ReportShape = function ( box: pq3Box ): Boolean of object;

  TBoxAllocator = class;
  TBodyAllocator = class;

  q3Scene = class
  private
    m_contactManager: q3ContactManager;
    m_boxAllocator: TBoxAllocator;
    m_bodyCount: i32;
    m_bodyList: pq3Body;
    m_stack: TArray<pq3Body>;
    m_bodyAllocator: TBodyAllocator;
    m_gravity: q3Vec3;
    m_base_iterations: i32;
    m_newBox: Boolean;
    m_allowSleep: Boolean;
    m_enableFriction: Boolean;
    m_island: q3Island;
    m_islandCount: i32;
    m_awakeCount: i32;
    m_showContact: Boolean;
    m_showAABB: Boolean;
    m_showLinks: Boolean;
  public
    constructor Create; overload;
    constructor Create(const gravity: q3Vec3 ); overload;
	  destructor Destroy; override;
  	procedure Step( dt: r32 = 1/60; iterations: i32 = 20 ); overload;
  	function CreateBody( const def: q3BodyDef ): pq3Body;
  	procedure RemoveBody( body: pq3Body );
	  procedure RemoveAllBodies( );
	  procedure SetAllowSleep( allowSleep: Boolean );
  	procedure SetIterations( iterations: i32 );
  	procedure SetEnableFriction( enabled: Boolean );
  	procedure Render( render: q3Render);
  	function  GetGravity: q3Vec3;
	  procedure SetGravity( const gravity: q3Vec3 );
  	procedure Shutdown;
  	procedure SetContactListener( listener: q3ContactListener );
  	procedure QueryAABB( cb: q3ReportShape; const aabb: q3AABB );
  	procedure QueryPoint( cb: q3ReportShape; const point: q3Vec3 );
  	procedure RayCast( cb: q3ReportShape; const rayCast: q3RaycastData );
    property bodyCount: i32 read m_bodyCount;
    property islandCount: i32 read m_islandCount;
    property awakeCount: i32 read m_awakeCount;
    property showContact: Boolean read m_showContact write m_showContact;
    property showAABB: Boolean read m_showAABB write m_showAABB;
    property showLinks: Boolean read m_showLinks write m_showLinks;
  end;

// dynamics/q3ContactSolver.h

  q3ContactSolver = record
    m_island: pq3Island;
    m_contacts: pq3ContactConstraintState;
    m_contactCount: i32;
    m_velocities: pq3VelocityState;
    m_enableFriction: Boolean;
    procedure Initialize( island: pq3Island);
    procedure ShutDown;
    procedure PreSolve( dt: r32 );
    procedure Solve;
  end;

// dynamics/q3Body.h

  q3BoxDef = record
  private
    m_tx: q3Transform;
    m_e: q3Vec3;
    m_friction: r32;
    m_restitution: r32;
    m_density: r32;
    m_sensor: Boolean;
  public
    class operator Initialize(out def: q3BoxDef);
    constructor Create(const tx: q3Transform; extents: q3Vec3);
    property friction: r32 read m_friction write m_friction;
    property restitution: r32 read m_restitution write m_restitution;
    property density: r32 read m_density write m_density;
    property sensor: Boolean read m_sensor write m_sensor;
  end;
  pq3BoxDef = ^q3BoxDef;


  q3Body = record
  const
    eAwake       = $001;
    eActive      = $002;
    eAllowSleep  = $004;
    eIsland      = $010;
    eStatic      = $020;
    eDynamic     = $040;
    eKinematic   = $080;
    eLockAxisX   = $100;
    eLockAxisY   = $200;
    eLockAxisZ   = $400;
  private
    m_invInertiaModel: q3Mat3;
    m_invInertiaWorld: q3Mat3;
    m_mass: r32;
    m_invMass: r32;
    m_linearVelocity: q3Vec3;
    m_angularVelocity: q3Vec3;
    m_force: q3Vec3;
    m_torque: q3Vec3;
    m_tx: q3Transform;
    m_q: q3Quaternion;
    m_localCenter: q3Vec3;
    m_worldCenter: q3Vec3;
    m_sleepTime: r32;
    m_gravityScale: r32;
    m_layers: i32;
    m_flags: i32;
    m_boxes: pq3Box;
    m_userData: Pointer;
    m_scene: q3Scene;
    m_next: pq3Body;
    m_prev: pq3Body;
    m_islandIndex: i32;
    m_linearDamping: r32;
    m_angularDamping: r32;
    m_contactList: pq3ContactEdge;
    procedure CalculateMassData;
    procedure SynchronizeProxies;
  public
    constructor Create(const def: q3BodyDef; scene: q3Scene);
    function AddBox(const def: q3BoxDef): pq3Box;
    procedure RemoveBox(box: pq3Box);
    procedure RemoveAllBoxes;
    procedure ApplyLinearForce(const force: q3Vec3);
    procedure ApplyForceAtWorldPoint(const force, point: q3Vec3);
    procedure ApplyLinearImpulse(const impulse: q3Vec3);
    procedure ApplyLinearImpulseAtWorldPoint(const impulse, point: q3Vec3);
    procedure ApplyTorque(const torque: q3Vec3);
    procedure SetToAwake; inline;
    procedure SetToSleep;
    function IsAwake: Boolean; inline;
    function GetGravityScale: r32;
    procedure SetGravityScale(scale: r32);
    function GetLocalPoint(const p: q3Vec3): q3Vec3;
    function GetLocalVector(const v: q3Vec3): q3Vec3;
    function GetWorldPoint(const p: q3Vec3): q3Vec3;
    function GetWorldVector(const v: q3Vec3): q3Vec3;
    function GetLinearVelocity: q3Vec3;
    function GetVelocityAtWorldPoint(const p: q3Vec3): q3Vec3;
    procedure SetLinearVelocity(const v: q3Vec3);
    function GetAngularVelocity: q3Vec3;
    procedure SetAngularVelocity(const v: q3Vec3);
    function CanCollide(other: pq3Body): Boolean;
    function GetTransform: q3Transform;
    function GetFlags: i32;
    procedure SetLayers(layers: i32);
    function GetLayers: i32;
    function GetQuaternion: q3Quaternion;
    function GetUserData: Pointer;
    procedure SetLinearDamping(damping: r32);
    function GetLinearDamping(damping: r32): r32;
    procedure SetAngularDamping(damping: r32);
    function GetAngularDamping(damping: r32): r32;
    procedure SetTransform(const position: q3Vec3); overload;
    procedure SetTransform(const position, axis: q3Vec3; angle: r32); overload;
    procedure Render(render: q3Render; showLinks: Boolean);
    function GetMass: r32;
    function GetInvMass: r32;
  end;

// collision/q3Box.h

   q3MassData = record
     inertia: q3Mat3;
     center: q3Vec3;
     mass: r32;
   end;

   q3Box = record
     local: q3Transform;
     e: q3Vec3;
     next: pq3Box;
     body: pq3Body;
     friction: r32;
     restitution: r32;
     density: r32;
     broadPhaseIndex: i32;
     userData: Pointer;
     sensor: Boolean;
     procedure SetUserData(data: Pointer);
     function GetUserData: Pointer;
     function TestPoint(const tx: q3Transform; const p: q3Vec3): Boolean;
     function Raycast(const tx: q3Transform; raycast: pq3RaycastData): Boolean;
     procedure ComputeAABB(const tx: q3Transform; var aabb: q3AABB);
     procedure ComputeMass(var md: q3MassData);
     procedure Render(const tx: q3Transform; awake: Boolean; render: q3Render; showLinks: Boolean);
   end;

  TContactConstraintAllocator = class(TPagedAllocator<q3ContactConstraint>)
  public
    function Allocate: pq3ContactConstraint; inline;
    procedure Release(contact: pq3ContactConstraint); inline;
  end;

  TBoxAllocator = class(TPagedAllocator<q3Box>)
  public
    function Allocate: pq3Box; inline;
    procedure Release(box: pq3Box); inline;
  end;

  TBodyAllocator = class(TPagedAllocator<q3Body>)
  public
    function Allocate: pq3Body; inline;
    procedure Release(body: pq3Body); inline;
  end;

// math.q3Math.inl

function q3Invert(a: r32): r32;
function q3Sign(a: r32): r32;
function q3Clamp01(val: r32): r32;
function q3Clamp(min, max, a: r32): r32;
function q3RandomFloat(l, h: r32): r32;

implementation

constructor TSlotPage<T>.Create;
begin
  for var I := 0 to High(FSlots) - 1 do
  begin
    FSlots[I].Next := @FSlots[I + 1];
    FSlots[I].Page := Self;
  end;
  FSlots[High(FSlots)].Page := Self;
  FFreeSlot := @FSlots[0];
end;

function TPagedAllocator<T>.AllocatePtr: Pointer;
begin
  if FFirstFree = nil then
  begin
    var Page := TSlotPage<T>.Create;
    Page.FNextPage := FFirstPage;
    FFirstPage := Page;
    FFirstFree := Page;
  end;
  Assert(FFirstFree.FFreeSlot <> nil);
  var Slot := FFirstFree.FFreeSlot;
  Assert(Slot.Page = FFirstFree);
  FFirstFree.FFreeSlot := Slot.Next;
  if FFirstFree.FFreeSlot = nil then
  begin
    FFirstFree := FFirstFree.FNextFree;
  end;
  Slot.Next := nil;
  FillChar(Slot.Data, SizeOf(T), 0);
   Assert(Slot.Page <> nil);
  Result := @Slot.Data;
end;

procedure TPagedAllocator<T>.ReleasePtr(P: Pointer);
var
  Slot: ^TSlot<T> absolute P;
begin
{$IFDEF DEBUG}
//  Assert(FFirstPage <> nil);
//  Assert(Slot.Next = nil);
//  var V: TSlotPage<T> := FFirstPage;
//  while (NativeUInt(P) < NativeUInt(@V.FSlots[0])) or (NativeUInt(P) > NativeUInt(@V.FSlots[V.SLOT_COUNT - 1])) do
//  begin
//    V := V.FNextPage;
//    Assert(V <> nil);
//  end;
//  if V <> Slot.Page then
//    Assert(V = Slot.Page);
{$ENDIF}
  var Page := Slot.Page;
  Slot.Next := Page.FFreeSlot;
  if Page.FFreeSlot = nil then
  begin
    Page.FNextFree := FFirstFree;
    FFirstFree := Page;
  end;
  Page.FFreeSlot := Slot;
end;

destructor TPagedAllocator<T>.Destroy;
begin
  Clear;
end;

procedure TPagedAllocator<T>.Clear;
begin
  while FFirstPage <> nil do
  begin
    var P := FFirstPage;
    FFirstPage := P.FNextPage;
    P.Free;
  end;
  FFirstFree := nil;
end;

function TContactConstraintAllocator.Allocate: pq3ContactConstraint;
begin
  Result := pq3ContactConstraint(AllocatePtr());
end;

procedure TContactConstraintAllocator.Release(contact: pq3ContactConstraint);
begin
  ReleasePtr(contact);
end;

function TBoxAllocator.Allocate: pq3Box;
begin
  Result := pq3Box(AllocatePtr());
end;

procedure TBoxAllocator.Release(box: pq3Box);
begin
  ReleasePtr(box);
end;

function TBodyAllocator.Allocate: pq3Body;
begin
  Result := pq3Body(AllocatePtr);
end;

procedure TBodyAllocator.Release(body: pq3Body);
begin
  ReleasePtr(body);
end;

const
  Epsilon:Single = 1.4012984643248170709e-45;

procedure swap(var a, b: u8); inline;
begin
  var t: u8 := a;
  a := b;
  b := t;
end;

{ q3Vec3 }

class function q3Vec3.Create(_x: r32; _y: r32; _z: r32): q3Vec3;
begin
  Result.SetXYZ(_x, _y, _z);
end;

procedure q3Vec3.SetXYZ(_x: r32; _y: r32; _z: r32);
begin
  x := _x;
  y := _y;
  z := _z;
end;

procedure q3Vec3.SetAll(a: r32);
begin
  x := a;
  y := a;
  z := a;
end;

procedure q3Vec3.Identity;
begin
  SetAll(0);
end;

function q3Vec3.Dot(const v: q3Vec3): r32;
begin
  Result := x * v.x + y * v.y + z * v.z;
end;

function q3Vec3.Cross(const v: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(
    (y * v.z) - (v.y * z),
    (v.x * z) - (x * v.z),
    (x * v.y) - (v.x * y)
  );
end;

function q3Vec3.Length: r32;
begin
  Result := sqrt(x * x + y * y + z * z);
end;

function q3Vec3.Normalize: q3Vec3;
begin
  var l: r32 := Length;
  if System.Abs(l) > Epsilon then
    Result := Self * (1.0/l)
  else
    Result := Self;
end;

function q3Vec3.Abs: q3Vec3;
begin
  Result.SetXYZ(System.Abs(x), System.Abs(y), System.Abs(z));
end;

function q3Vec3.Min(const v: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(System.Math.Min(x, v.x), System.Math.Min(y, v.y), System.Math.Min(z, v.Z));
end;

function q3Vec3.Max(const v: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(System.Math.Max(x, v.x), System.Math.Max(y, v.y), System.Math.Max(z, v.Z));
end;

procedure q3Vec3.ComputeBasis(var b, c: q3Vec3);
begin
  if System.Abs(x) >= 0.57735027 then
    b.SetXYZ(y, -x, 0)
  else
    b.SetXYZ(0, z, -y);
  b := b.Normalize;
  c := Cross( b );
end;

class operator q3Vec3.Add(const a, b: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(a.x + b.x, a.y + b.y, a.z + b.z);
end;

class operator q3Vec3.Subtract(const a, b: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(a.x - b.x, a.y - b.y, a.z - b.z);
end;

class operator q3Vec3.Multiply(const a, b: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(a.x * b.x, a.y * b.y, a.z * b.z);
end;

class operator q3Vec3.Multiply(const v: q3Vec3; const f: Single): q3Vec3;
begin
  Result.SetXYZ(v.x * f, v.y * f, v.z * f);
end;

class operator q3Vec3.Divide(const v: q3Vec3; const f: Single): q3Vec3;
begin
  Result.SetXYZ(v.x / f, v.y / f, v.z / f);
end;

class operator q3Vec3.Negative(const v: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(-v.x, -v.y, -v.z);
end;

constructor q3Mat3.Create(a: r32; b: r32; c: r32; d: r32; e: r32; f: r32; g: r32; h: r32; i: r32);
begin
  ex.SetXYZ(a, b, c);
  ey.SetXYZ(d, e, f);
  ez.SetXYZ(g, h, i);
end;

procedure q3Mat3.SetRows(const _x: q3Vec3; const _y: q3Vec3; const _z: q3Vec3);
begin
  ex := _x;
  ey := _y;
  ez := _z;
end;

constructor q3Mat3.Create(const axis: q3Vec3; angle: r32);
begin
  var s: r32 := sin(angle);
  var c: r32 := cos(angle);
  var x: r32 := axis.x;
  var y: r32 := axis.y;
  var z: r32 := axis.z;
  var xy: r32 := x * y;
  var yz: r32 := y * z;
  var zx: r32 := z * x;
  var t: r32 := 1.0 - c;
  Create(
    x * x * t + c, xy * t + z * s, zx * t - y * s,
		xy * t - z * s, y * y * t + c, yz * t + x * s,
		zx * t + y * s, yz * t - x * s, z * z * t + c
  );
end;

procedure q3Mat3.Identity;
begin
  ex.SetXYZ(1, 0, 0);
  ey.SetXYZ(0, 1, 0);
  ez.SetXYZ(0, 0, 1);
end;

function q3Mat3.Transpose: q3Mat3;
begin
  Result.Create(
    ex.x, ey.x, ez.x,
		ex.y, ey.y, ez.y,
		ex.z, ey.z, ez.z
  );
end;

function q3Mat3.Inverse: q3Mat3;
begin
  var tmp0, tmp1, tmp2: q3Vec3;
  var detinv: r32;

  tmp0 := ey.Cross( ez );
	tmp1 := ez.Cross( ex );
	tmp2 := ex.Cross( ey );

  detinv := r32( 1.0 ) / ez.Dot( tmp2 );

  Result.Create(
    tmp0.x * detinv, tmp1.x * detinv, tmp2.x * detinv,
		tmp0.y * detinv, tmp1.y * detinv, tmp2.y * detinv,
		tmp0.z * detinv, tmp1.z * detinv, tmp2.z * detinv
  );
end;

class function q3Mat3.Diagonal1(a: r32): q3Mat3;
begin
  Result := Diagonal3(a, a, a);
end;

class function q3Mat3.Diagonal3(a, b, c: r32): q3Mat3;
begin
  Result.Create(
    a, 0, 0,
    0, b, 0,
    0, 0, c
  );
end;

class operator q3Mat3.Add(const m1, m2: q3Mat3): q3Mat3;
begin
  Result.SetRows( m1.ex + m2.ex, m1.ey + m2.ey, m1.ez + m2.ez);
end;

class operator q3Mat3.Subtract(const m1, m2: q3Mat3): q3Mat3;
begin
  Result.SetRows( m1.ex - m2.ex, m1.ey - m2.ey, m1.ez - m2.ez);
end;

class operator q3Mat3.Multiply(const m: q3Mat3; f: r32): q3Mat3;
begin
  Result.SetRows(m.ex * f, m.ey * f, m.ez * f);
end;

class operator q3Mat3.Multiply(const m: q3Mat3; const rhs: q3Vec3): q3Vec3;
begin
  Result.SetXYZ(
    m.ex.x * rhs.x + m.ey.x * rhs.y + m.ez.x * rhs.z,
		m.ex.y * rhs.x + m.ey.y * rhs.y + m.ez.y * rhs.z,
		m.ex.z * rhs.x + m.ey.z * rhs.y + m.ez.z * rhs.z
  );
end;

class operator q3Mat3.Multiply(const m, rhs: q3Mat3): q3Mat3;
begin
  Result.SetRows(
    m * rhs.ex,
    m * rhs.ey,
    m * rhs.ez
  );
end;

function q3Mat3.Column0: q3Vec3;
begin
  Result.SetXYZ( ex.x, ey.x, ez.x );
end;

function q3Mat3.Column1: q3Vec3;
begin
  Result.SetXYZ( ex.y, ey.y, ez.y );
end;

function q3Mat3.Column2: q3Vec3;
begin
  Result.SetXYZ( ex.z, ey.z, ez.z );
end;

function q3Vec3Helper.OuterProduct(const v: q3Vec3): q3Mat3;
begin
  var a: q3Vec3 := v * x;
  var b: q3Vec3 := v * y;
  var c: q3Vec3 := v * z;

  Result.Create(
    a.x, a.y, a.z,
		b.x, b.y, b.z,
		c.x, c.y, c.z
  );
end;

constructor q3Quaternion.Create(a, b, c, d: r32);
begin
  x := a;
  y := b;
  z := c;
  w := d;
end;

constructor q3Quaternion.Create(const axis: q3Vec3; radians: r32);
begin
  var halfAngle: r32 := 0.5 * radians;
  var s: r32 := sin(halfAngle);
  x := s * axis.x;
  y := s * axis.y;
  z := s * axis.z;
  w := cos(halfAngle);
end;

procedure q3Quaternion.ToAxisAngle(var axis: q3Vec3; var angle: r32);
begin
  Assert(w <= 1.0);
  angle := 2.0 * ArcCos(w);
  var l: r32 := sqrt(1.0 - w * w);
  if Abs(l) < Epsilon then
    axis.SetXYZ(0, 0, 0)
  else begin
    l := 1.0 / l;
    axis.SetXYZ(x * l, y * l, z * l);
  end;
end;

procedure q3Quaternion.Integrate(const dv: q3Vec3; dt: r32);
begin
  var q := q3Quaternion.Create(dv.x * dt, dv.y * dt, dv.z * dt, 0);
  q := q * Self;
  x := x + q.x * 0.5;
  y := y + q.y * 0.5;
  z := z + q.z * 0.5;
  w := w + q.w * 0.5;

  Normalize;
end;

procedure q3Quaternion.Normalize;
begin
  var d: r32 := w * w + x * x + y * y + z * z;

  if Abs(d) > Epsilon then
  begin
    d := 1.0/sqrt(d);
    if d > 1.0e-8 then
    begin
      x := x * d;
      y := y * d;
      z := z * d;
      w := w * d;
    end;
  end;
end;

function q3Quaternion.ToMat3: q3Mat3;
begin
  var qx2: r32 := x + x;
  var qy2: r32 := y + y;
  var qz2: r32 := z + z;
	var qxqx2 : r32 := x * qx2;
	var qxqy2 : r32 := x * qy2;
	var qxqz2 : r32 := x * qz2;
	var qxqw2 : r32 := w * qx2;
	var qyqy2 : r32 := y * qy2;
	var qyqz2 : r32 := y * qz2;
	var qyqw2 : r32 := w * qy2;
	var qzqz2 : r32 := z * qz2;
	var qzqw2 : r32 := w * qz2;

	Result.Create(
		r32( 1.0 ) - qyqy2 - qzqz2, qxqy2 + qzqw2, qxqz2 - qyqw2,
		qxqy2 - qzqw2, r32( 1.0 ) - qxqx2 - qzqz2, qyqz2 + qxqw2,
		qxqz2 + qyqw2, qyqz2 - qxqw2, r32( 1.0 ) - qxqx2 - qyqy2
  );
end;

class operator q3Quaternion.Multiply(const a, b: q3Quaternion): q3Quaternion;
begin
  Result.Create(
		a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
		a.w * b.y + a.y * b.w + a.z * b.x - a.x * b.z,
		a.w * b.z + a.z * b.w + a.x * b.y - a.y * b.x,
		a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
  );
end;

function q3Invert(a: r32): r32;
begin
  if Abs(a) > Epsilon then
    Result := 1 / a
  else
    Result := 0;
end;

function q3Sign(a: r32): r32;
begin
  if a >= 0 then
    Result := 1
  else
    Result := -1;
end;

function q3Clamp01(val: r32): r32;
begin
  if val >= 1.0 then
    Result := 1.0
  else
  if val <= 0.0 then
    Result := 0.0
  else
    Result := val;
end;

function q3Clamp(min, max, a: r32): r32;
begin
  if a <= min then
    Result := min
  else
  if a >= max then
    Result := max
  else
    Result := a;
end;

function q3RandomFloat(l, h: r32): r32;
begin
  Result := l + (h - l) * Random;
end;

function Q3_PTR_ADD(p: Pointer; i: i32): Pointer; inline;
begin
  Result := PByte(p) + i;
end;

function q3AABB.Contains(const other: q3AABB): Boolean;
begin
  Result := (min.x <= other.min.x)
        and (min.y <= other.min.y)
        and (min.z <= other.min.z)
        and (max.x >= other.max.x)
        and (max.y >= other.max.y)
        and (max.z >= other.max.z);
end;

function q3AABB.Contains(const point: q3Vec3): Boolean;
begin
  Result := (min.x <= point.x)
        and (min.y <= point.y)
        and (min.z <= point.z)
        and (max.x >= point.x)
        and (max.y >= point.y)
        and (max.z >= point.z);
end;

function q3AABB.SurfaceArea: r32;
begin
  var x: r32 := max.x - min.x;
  var y: r32 := max.y - min.y;
  var z: r32 := max.z - min.z;

  Result := 2.0 * (x * y + x * z + y * z);
end;

function q3AABB.Combine(const q: q3AABB): q3AABB;
begin
  Result.min := min.Min( q.min);
  Result.max := max.Max( q.max);
end;

function q3AABB.AABBtoAABB(const q: q3AABB): Boolean;
begin
  if (max.x < q.min.x) or (min.x > q.max.x) then
    Exit(False);

  if (max.y < q.min.y) or (min.y > q.max.y) then
    Exit(False);

  if (max.z < q.min.z) or (min.z > q.max.z) then
    Exit(False);

  Result := True;
end;

constructor q3RaycastData.Create(const startPoint, direction: q3Vec3; endPointTime: r32);
begin
  start := startPoint;
	dir := direction;
	t := endPointTime;
end;

function q3RaycastData.GetImpactPoint: q3Vec3;
begin
  Result := start + dir * toi;
end;

procedure FattenAABB(var aabb: q3AABB);
const
  k_fatterner = 0.1;
begin
  Exit;
  var v := q3Vec3.Create(k_fatterner, k_fatterner, k_fatterner);
  aabb.min := aabb.min - v;
  aabb.max := aabb.max + v;
end;

function q3DynamicAABBTree.Node.IsLeaf: Boolean;
begin
  // The right leaf does not use the same memory as the userdata,
  // and will always be Null (no children)
  Result := right = Null;
end;

constructor q3DynamicAABBTree.Create;
begin
  m_capacity := 1024;
  SetLength(m_nodes, m_capacity);
  m_root := Node.Null;
  AddToFreeList(0);
end;

function q3DynamicAABBTree.Insert(const aabb: q3AABB; userData: Pointer): i32;
begin
  var id: i32 := AllocateNode();
  m_nodes[id].aabb := aabb;
  FattenAABB(m_nodes[id].aabb);
  m_nodes[id].userData := userData;
  m_nodes[id].height := 0;

  InsertLeaf(id);

  Result := id;
end;

procedure q3DynamicAABBTree.Remove(id: i32);
begin
  assert((id >= 0) and (id < m_capacity));
  assert(m_nodes[ id ].IsLeaf());

  RemoveLeaf(id);
  DeallocateNode(id);
end;

function q3DynamicAABBTree.Update(id: i32; const aabb: q3AABB): Boolean;
begin
  assert((id >= 0) and (id < m_capacity));
  assert(m_nodes[ id ].IsLeaf());

  if m_nodes[id].aabb.Contains(aabb) then
    Exit(False);

  RemoveLeaf(id);

  m_nodes[id].aabb := aabb;
  FattenAABB(m_nodes[id].aabb);
  InsertLeaf(id);

  Result := True;
end;

function q3DynamicAABBTree.GetUserData(id: i32): Pointer;
begin
  assert((id >= 0) and (id < m_capacity));
  Result := m_nodes[id].userData;
end;

function q3DynamicAABBTree.GetFatAABB(id: i32): q3AABB;
begin
  assert((id >= 0) and (id < m_capacity));
  Result := m_nodes[id].aabb;
end;

procedure q3DynamicAABBTree.Render(render: q3Render);
begin
  if m_root <> Node.Null then
  begin
    //render.SetPenColor(0.5, 0.5, 1.0);
    RenderNode(render, m_root);
  end;
end;

procedure q3DynamicAABBTree.RenderNode(render: q3Render; index: i32);
begin
  assert((index >= 0) and (index < m_capacity));
  var n: pNode := @m_nodes[index];
  var b: pq3AABB := @n.aabb;

  if n.IsLeaf then
    render.SetPenColor(0.5, 1.0, 1.0)
  else
    render.SetPenColor(0.5, 0.5, 1.0);


  render.SetPenPosition(b.min.x, b.max.y, b.min.z);

	render.Line( b.min.x, b.max.y, b.max.z );
	render.Line( b.max.x, b.max.y, b.max.z );
	render.Line( b.max.x, b.max.y, b.min.z );
	render.Line( b.min.x, b.max.y, b.min.z );

	render.SetPenPosition( b.min.x, b.min.y, b.min.z );

	render.Line( b.min.x, b.min.y, b.max.z );
	render.Line( b.max.x, b.min.y, b.max.z );
	render.Line( b.max.x, b.min.y, b.min.z );
	render.Line( b.min.x, b.min.y, b.min.z );

	render.SetPenPosition( b.min.x, b.min.y, b.min.z );
	render.Line( b.min.x, b.max.y, b.min.z );
	render.SetPenPosition( b.max.x, b.min.y, b.min.z );
	render.Line( b.max.x, b.max.y, b.min.z );
	render.SetPenPosition( b.max.x, b.min.y, b.max.z );
	render.Line( b.max.x, b.max.y, b.max.z );
	render.SetPenPosition( b.min.x, b.min.y, b.max.z );
	render.Line( b.min.x, b.max.y, b.max.z );

  if not n.IsLeaf then
  begin
    RenderNode(render, n.left);
    RenderNode(render, n.right);
  end;
end;

procedure q3DynamicAABBTree.Validate;
begin
  var freeNodes: i32 := 0;
  var index: i32 := m_freeList;

  while index <> Node.Null do
  begin
    assert((index >= 0) and (index < m_capacity));
    index := m_nodes[index].next;
    Inc(freeNodes);
  end;

  assert(m_count + freeNodes = m_capacity);

  if m_root <> Node.Null then
  begin
    assert(m_nodes[m_root].parent = Node.Null);
  {$IFDEF DEBUG}
    ValidateStructure(m_root);
  {$ENDIF}
  end;
end;

procedure q3DynamicAABBTree.ValidateStructure(index: i32);
begin
  var n: pNode := @m_nodes[index];

  var il: i32 := n.left;
  var ir: i32 := n.right;

  if n.IsLeaf then
  begin
    assert(ir = Node.Null);
    assert(n.height = 0);
    Exit;
  end;

  assert((il >= 0) and (il < m_capacity));
  assert((ir >= 0) and (ir < m_capacity));
  var l: pNode := @m_nodes[il];
  var r: pNode := @m_nodes[ir];

  assert(l.parent = index);
  assert(r.parent = index);

  ValidateStructure(il);
  ValidateStructure(ir);
end;

function q3DynamicAABBTree.AllocateNode: i32;
begin
  if m_freeList = Node.Null then
  begin
    m_capacity := m_capacity * 2;
    SetLength(m_nodes, m_capacity);
    AddToFreeList(m_count);
  end;

  var freeNode: i32 := m_freeList;
  m_freeList := m_nodes[m_freeList].next;
  m_nodes[freeNode].height := 0;
  m_nodes[freeNode].left := Node.Null;
  m_nodes[freeNode].right := Node.Null;
  m_nodes[freeNode].parent := Node.Null;
  m_nodes[freeNode].userData := nil;
  Inc(m_count);
  Result := freeNode;
end;

function q3DynamicAABBTree.Balance(iA: i32): i32;
begin
	var A: pNode := @m_nodes[iA];

	if A.IsLeaf()  or (A.height = 1 ) then
		Exit(iA);

	(*      A
	      /   \
	     B     C
	    / \   / \
	   D   E F   G
	*)

	var iB: i32 := A.left;
	var iC: i32 := A.right;
	var B: pNode := @m_nodes[iB];
	var C: pNode := @m_nodes[iC];

	var balance: i32 := C.height - B.height;

	if balance > 1 then
	begin
		var _iF: i32 := C.left;
		var iG: i32 := C.right;
		var F: pNode := @m_nodes[_iF];
		var G: pNode := @m_nodes[iG];

		if A.parent <> Node.Null then
		begin
			if m_nodes[ A.parent ].left = iA then
				m_nodes[ A.parent ].left := iC
			else
				m_nodes[ A.parent ].right := iC;
		end
		else
			m_root := iC;

		C.left := iA;
		C.parent := A.parent;
		A.parent := iC;

		if F.height > G.height then
		begin
			C.right := _iF;
			A.right := iG;
			G.parent := iA;
			A.aabb := B.aabb.Combine( G.aabb );
			C.aabb := A.aabb.Combine( F.aabb );

			A.height := 1 + Max( B.height, G.height );
			C.height := 1 + Max( A.height, F.height );
		end

		else
		begin
			C.right := iG;
			A.right := _iF;
			F.parent := iA;
			A.aabb := B.aabb.Combine( F.aabb );
			C.aabb := A.aabb.Combine( G.aabb );

			A.height := 1 + Max( B.height, F.height );
			C.height := 1 + Max( A.height, G.height );
		end;

		Exit(iC);
	end

	// B is higher, promote B
	else if balance < -1 then
	begin
		var iD: i32 := B.left;
		var iE: i32 := B.right;
		var D: pNode := @m_nodes[iD];
		var E: pNode := @m_nodes[iE];

		if A.parent <> Node.Null then
		begin
			if(m_nodes[ A.parent ].left = iA) then
				m_nodes[ A.parent ].left := iB
			else
				m_nodes[ A.parent ].right := iB;
		end

		else
			m_root := iB;

		B.right := iA;
		B.parent := A.parent;
		A.parent := iB;

		if D.height > E.height then
		begin
			B.left := iD;
			A.left := iE;
			E.parent := iA;
			A.aabb := C.aabb.Combine( E.aabb );
			B.aabb := A.aabb.Combine( D.aabb );

			A.height := 1 + Max( C.height, E.height );
			B.height := 1 + Max( A.height, D.height );
		end

		else
		begin
			B.left := iE;
			A.left := iD;
			D.parent := iA;
			A.aabb := C.aabb.Combine( D.aabb );
			B.aabb := A.aabb.Combine( E.aabb );

			A.height := 1 + Max( C.height, D.height );
			B.height := 1 + Max( A.height, E.height );
		end;

		Exit(iB);
	end;

	Result := iA;
end;

procedure q3DynamicAABBTree.InsertLeaf(id: i32);
begin
	if m_root = Node.Null then
	begin
		m_root := id;
		m_nodes[ m_root ].parent := Node.Null;
		Exit;
	end;

	var searchIndex: i32 := m_root;
	var leafAABB: q3AABB := m_nodes[ id ].aabb;
	while not m_nodes[ searchIndex ].IsLeaf() do
	begin
		var combined: q3AABB := leafAABB.Combine( m_nodes[ searchIndex ].aabb );
		var combinedArea: r32 := combined.SurfaceArea( );
		var branchCost: r32 := 2.0 * combinedArea;

		var inheritedCost: r32 := 2.0 * (combinedArea - m_nodes[ searchIndex ].aabb.SurfaceArea());

		var left: i32 := m_nodes[ searchIndex ].left;
		var right: i32 := m_nodes[ searchIndex ].right;

		var leftDescentCost: r32;
		if m_nodes[left].IsLeaf() then
			leftDescentCost := leafAABB.Combine( m_nodes[left].aabb ).SurfaceArea( ) + inheritedCost
		else
		begin
			var inflated: r32 := leafAABB.Combine( m_nodes[left].aabb ).SurfaceArea( );
			var branchArea: r32 := m_nodes[ left ].aabb.SurfaceArea( );
			leftDescentCost := inflated - branchArea + inheritedCost;
		end;

		var rightDescentCost: r32;
		if m_nodes[right].IsLeaf() then
			rightDescentCost := leafAABB.Combine( m_nodes[right].aabb ).SurfaceArea( ) + inheritedCost
		else
		begin
			var inflated: r32 := leafAABB.Combine( m_nodes[right].aabb ).SurfaceArea( );
			var branchArea: r32 := m_nodes[ right ].aabb.SurfaceArea( );
			rightDescentCost := inflated - branchArea + inheritedCost;
		end;

		// Determine traversal direction, or early out on a branch index
		if ( branchCost < leftDescentCost ) and ( branchCost < rightDescentCost ) then
			break;

		if leftDescentCost < rightDescentCost then
			searchIndex := left

		else
			searchIndex := right;
	end;

	var sibling: i32 := searchIndex;

	var oldParent: i32 := m_nodes[sibling].parent;
	var newParent: i32 := AllocateNode( );
	m_nodes[ newParent ].parent := oldParent;
	m_nodes[ newParent ].userData := nil;
	m_nodes[ newParent ].aabb := leafAABB.Combine( m_nodes[sibling].aabb );
	m_nodes[ newParent ].height := m_nodes[sibling].height + 1;

	if oldParent = Node.Null then
	begin
		m_nodes[ newParent ].left := sibling;
		m_nodes[ newParent ].right := id;
		m_nodes[ sibling ].parent := newParent;
		m_nodes[ id ].parent := newParent;
		m_root := newParent;
	end

	else
	begin
		if m_nodes[ oldParent ].left = sibling then
			m_nodes[ oldParent ].left := newParent

		else
			m_nodes[ oldParent ].right := newParent;

		m_nodes[ newParent ].left := sibling;
		m_nodes[ newParent ].right := id;
		m_nodes[ sibling ].parent := newParent;
		m_nodes[ id ].parent := newParent;
	end;

	SyncHeirarchy( m_nodes[ id ].parent );
end;

procedure q3DynamicAABBTree.RemoveLeaf(id: i32);
begin
	if id = m_root then
	begin
		m_root := Node.Null;
		Exit;
	end;

	// Setup parent, grandParent and sibling
	var parent: i32 := m_nodes[ id ].parent;
	var grandParent: i32 := m_nodes[parent].parent;
	var sibling: i32;

	if m_nodes[ parent ].left = id then
		sibling := m_nodes[ parent ].right

	else
		sibling := m_nodes[ parent ].left;

	if grandParent <> Node.Null then
	begin
		if m_nodes[ grandParent ].left = parent then
			m_nodes[ grandParent ].left := sibling

		else
			m_nodes[ grandParent ].right := sibling;

		m_nodes[ sibling ].parent := grandParent;
	end

	else
	begin
		m_root := sibling;
		m_nodes[ sibling ].parent := Node.Null;
	end;

	DeallocateNode( parent );
	SyncHeirarchy( grandParent );
end;

procedure q3DynamicAABBTree.SyncHeirarchy(index: i32);
begin
	while index <> Node.Null do
	begin
		index := Balance( index );

		var left: i32 := m_nodes[ index ].left;
		var right: i32 := m_nodes[ index ].right;

		m_nodes[ index ].height := 1 + Max( m_nodes[ left ].height, m_nodes[ right ].height );
		m_nodes[ index ].aabb := m_nodes[ left ].aabb.Combine( m_nodes[ right ].aabb );

		index := m_nodes[ index ].parent;
  end;
end;

procedure q3DynamicAABBTree.AddToFreeList(index: i32);
begin
  for var i: i32 := index to m_capacity - 1 do
  begin
    m_nodes[ i ].next := i + 1;
    m_nodes[ i ].height := Node.Null;
  end;
  m_nodes[m_capacity - 1].next := Node.Null;
  m_nodes[m_capacity - 1].height := Node.Null;
  m_freeList := index;
end;

procedure q3DynamicAABBTree.DeallocateNode(index: i32);
begin
  assert((index >= 0) and (index < m_capacity));

  m_nodes[ index ].next := m_FreeList;
  m_nodes[ index ].height := Node.Null;
  m_freeList := index;

  Dec(m_count);
end;

procedure q3DynamicAABBTree.Query(cb: q3CallBack; const aabb: q3AABB);
const
  k_stackCapacity = 256;
begin
  var stack: array[0..k_stackCapacity - 1] of i32;
  var sp: i32 := 1;

  stack[0] := m_root;

  while sp <> 0 do
  begin
    assert(sp < k_stackCapacity);

    Dec(sp);
    var id: i32 := stack[sp];

    var n: pNode := @m_nodes[id];
    if aabb.AABBtoAABB( n.aabb) then
    begin
      if n.IsLeaf then
      begin
        if not cb(id) then
          Exit;
      end else begin
        stack[sp] := n.Left; Inc(sp);
        stack[sp] := n.right; Inc(sp);
      end;
    end;
  end;
end;

procedure q3DynamicAABBTree.Query(cb: q3CallBack; const rayCast: q3RaycastData);
const
  k_epsilon = 1.0e-6;
	k_stackCapacity = 256;
begin
	var stack: array[0..k_stackCapacity - 1] of i32;
	var sp: i32 := 1;

	stack[0] := m_root;

	var p0: q3Vec3 := rayCast.start;
	var p1: q3Vec3 := p0 + rayCast.dir * rayCast.t;

	while sp <> 0 do
	begin
		assert( sp < k_stackCapacity );

    Dec(sp);
		var id: i32 := stack[sp];

		if id = Node.Null then
			continue;

		var n: pNode := @m_nodes[id];

		var e: q3Vec3 := n.aabb.max - n.aabb.min;
		var d: q3Vec3 := p1 - p0;
		var m: q3Vec3 := p0 + p1 - n.aabb.min - n.aabb.max;

		var adx:r32 := Abs( d.x );

		if Abs( m.x ) > e.x + adx then
			continue;

		var ady: r32 := Abs( d.y );

		if Abs( m.y ) > e.y + ady then
			continue;

		var adz: r32 := Abs( d.z );

		if Abs( m.z ) > e.z + adz then
			continue;

		adx := adx + k_epsilon;
		ady := ady + k_epsilon;
		adz := adz + k_epsilon;

		if Abs( m.y * d.z - m.z * d.y) > e.y * adz + e.z * ady then
			continue;

		if Abs( m.z * d.x - m.x * d.z) > e.x * adz + e.z * adx then
			continue;

		if Abs( m.x * d.y - m.y * d.x) > e.x * ady + e.y * adx then
			continue;

		if n.IsLeaf() then
		begin
			if  not cb{.TreeCallBack}( id ) then
				Exit;
		end

		else
		begin
			stack[ sp ] := n.left; Inc(sp);
			stack[ sp ] := n.right; Inc(sp);
		end;
	end;
end;

constructor q3BroadPhase.Create(manager: q3ContactManager);
begin
  m_manager := manager;
  m_tree := q3DynamicAABBTree.Create;
  m_pairCapacity := 64;
  SetLength(m_pairBuffer, m_pairCapacity);
  m_moveCapacity := 64;
  SetLength(m_moveBuffer, m_moveCapacity);
end;

destructor q3BroadPhase.Destroy;
begin
  m_moveBuffer := nil;
  m_pairBuffer := nil;
  m_tree.Free;
end;

function q3BroadPhase.TreeCallBack(index: i32): Boolean;
begin
  // Cannot collide with self
	if index = m_currentIndex then
		Exit(True);

	if m_pairCount = m_pairCapacity then
	begin
		m_pairCapacity := m_pairCapacity * 2;
		SetLength(m_pairBuffer, m_pairCapacity);
	end;

	var iA: i32 := Min( index, m_currentIndex );
	var iB: i32 := Max( index, m_currentIndex );

	m_pairBuffer[ m_pairCount ].A := iA;
	m_pairBuffer[ m_pairCount ].B := iB;
	Inc(m_pairCount);

	Result := true;
end;

procedure q3BroadPhase.InsertBox(box: pq3Box; const aabb: q3AABB);
begin
  var id: i32 := m_tree.Insert(aabb, box);
  box.broadPhaseIndex := id;
  BufferMove( id );
end;

procedure q3BroadPhase.RemoveBox(box: pq3Box);
begin
  m_tree.Remove(box.broadPhaseIndex);
end;

function ContactPairSort(const lhs, rhs: q3ContactPair): Boolean;
begin
  if lhs.A < rhs.A then
  begin
    Result := True;
  end else begin
    if lhs.A = rhs.A then
    begin
      Result := lhs.B < rhs.B;
    end else begin
      Result := False;
    end;
  end;
end;

type
  TQSCompare = function(const l, r: q3ContactPair): Boolean;

procedure QuickSort(SortList: pq3ContactPair; L, R: NativeInt;
  const SCompare: TQSCompare);
var
  I, J: NativeInt;
  P, T: q3ContactPair;
begin
  if L < R then
  begin
    repeat

      if (R - L) = 1 then
      begin
        if not SCompare(SortList[L], SortList[R]) then
        begin
          T := SortList[L];
          SortList[L] := SortList[R];
          SortList[R] := T;
        end;
        break;
      end;
      I := L;
      J := R;
      P := SortList[(L + R) shr 1];
      repeat
        while SCompare(SortList[I], P) do
          Inc(I);
        while SCompare(P, SortList[J]) do
          Dec(J);
        if I <= J then
        begin
          if I <> J then
          begin
            T := SortList[I];
            SortList[I] := SortList[J];
            SortList[J] := T;
          end;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if (J - L) > (R - I) then
      begin
        if I < R then
          QuickSort(SortList, I, R, SCompare);
        R := J;
      end
      else
      begin
        if L < J then
          QuickSort(SortList, L, J, SCompare);
        L := I;
      end;
    until L >= R;
  end;
end;

procedure q3BroadPhase.UpdatePairs;
begin
  m_pairCount := 0;

	for var i:i32 := 0 to m_moveCount - 1 do
	begin
		m_currentIndex := m_moveBuffer[ i ];
		var aabb: q3AABB := m_tree.GetFatAABB( m_currentIndex );

		m_tree.Query( TreeCallBack, aabb );
	end;

	m_moveCount := 0;

 	QuickSort( @m_pairBuffer[0], 0, m_pairCount - 1, ContactPairSort );

  begin
    var i: i32  := 0;
		while i < m_pairCount do
		begin
			var pair: pq3ContactPair := @m_pairBuffer[ i ];
			var A: pq3Box := pq3Box(m_tree.GetUserData( pair.A ));
			var B: pq3Box := pq3Box(m_tree.GetUserData( pair.B ));
			m_manager.AddContact( A, B );

			Inc(i);

      while i < m_pairCount do
			begin
				var potentialDup: pq3ContactPair := @m_pairBuffer[ i ];

				if ( pair.A <> potentialDup.A) or (pair.B <> potentialDup.B ) then
					break;

				Inc(i);
			end;
		end;
	end;

	m_tree.Validate( );
end;

procedure q3BroadPhase.Update(id: i32; const aabb: q3AABB);
begin
  if m_tree.Update(id, aabb) then
    BufferMove(id);
end;

function q3BroadPhase.TestOverlap(A: i32; B: i32): Boolean;
begin
  Result := m_tree.GetFatAABB(A).AABBtoAABB( m_tree.GetFatAABB(B) );
end;

procedure q3BroadPhase.BufferMove(id: i32);
begin
  if m_moveCount = m_moveCapacity then
  begin
    m_moveCapacity := m_moveCapacity * 2;
    SetLength(m_moveBuffer, m_moveCapacity);
  end;
  m_moveBuffer[m_moveCount] := id;
  Inc(m_moveCount);
end;

procedure q3Manifold.SetPair(a: pq3Box; b: pq3Box);
begin
  Self.A := a;
  Self.B := b;
  sensor := A.sensor or B.sensor;
end;

function q3Mul(const tx: q3Transform; const v: q3Vec3): q3Vec3; overload;
begin
  Result := tx.rotation * v + tx.position;
end;

function q3MulT(const tx: q3Transform; const v: q3Vec3): q3Vec3; overload;
begin
  Result := tx.rotation.Transpose * (v - tx.position);
end;

function q3MulT(const r, v: q3Mat3): q3Mat3; inline; overload;
begin
  Result := r.Transpose * v;
end;

function q3MulT(const r: q3Mat3; const v: q3Vec3): q3Vec3; inline; overload;
begin
  Result := r.Transpose * v;
end;

function q3Mul(const t, u: q3Transform): q3Transform; overload;
begin
  Result.rotation := t.rotation * u.rotation;
  Result.position := t.rotation * u.position + t.position;
end;

function q3MulT(const t, u: q3Transform): q3Transform; overload;
begin
  Result.rotation := q3MulT(t.rotation, u.rotation);
  Result.position := q3MulT(t.rotation, u.position - t.position);
end;

function q3TrackFaceAxis(var axis: i32; n: i32; s: r32; var sMax: r32; const normal: q3Vec3; var axisNormal: q3Vec3): Boolean;
begin
	if s > 0.0 then
		Exit(true);

	if s > sMax then
	begin
		sMax := s;
		axis := n;
		axisNormal := normal;
	end;

	Result := False;
end;

function q3TrackEdgeAxis(var axis: i32; n: i32; s: r32; var sMax: r32; const normal: q3Vec3; var axisNormal: q3Vec3): Boolean;
begin
	if s > 0.0 then
		Exit(True);

	var l: r32 := 1.0 / normal.Length;
	s := s * l;

	if s > sMax then
	begin
		sMax := s;
		axis := n;
		axisNormal := normal * l;
	end;

	Result := False;
end;

type
  q3ClipVertex = record
	  v: q3Vec3;
	  f: q3FeaturePair;
    class operator Initialize(out c: q3ClipVertex);
  end;
  pq3ClipVertex = ^q3ClipVertex;

class operator q3ClipVertex.Initialize (out c: q3ClipVertex);
begin
  c.f.key := not 0;
end;

function q3Clip( const rPos, e: q3Vec3; clipEdges: pu8; const basis: q3Mat3; incident, outVerts: pq3ClipVertex; outDepths: pr32 ): i32; forward;

procedure q3ComputeReferenceEdgesAndBasis( const eR: q3Vec3; const rtx: q3Transform; n: q3Vec3; axis: i32; _out: pu8; var basis: q3Mat3; var e: q3Vec3 );
begin
	n := q3MulT( rtx.rotation, n );

	if axis >= 3 then
		Dec(axis, 3);

	case axis of
	  0:
		if n.x > 0.0 then
		begin
			_out[ 0 ] := 1;
			_out[ 1 ] := 8;
			_out[ 2 ] := 7;
			_out[ 3 ] := 9;

			e.SetXYZ( eR.y, eR.z, eR.x );
			basis.SetRows( rtx.rotation.ey, rtx.rotation.ez, rtx.rotation.ex );
		end

		else
		begin
			_out[ 0 ] := 11;
			_out[ 1 ] := 3;
			_out[ 2 ] := 10;
			_out[ 3 ] := 5;

			e.SetXYZ( eR.z, eR.y, eR.x );
			basis.SetRows( rtx.rotation.ez, rtx.rotation.ey, -rtx.rotation.ex );
		end;


	  1:
		if n.y > 0.0 then
		begin
			_out[ 0 ] := 0;
			_out[ 1 ] := 1;
			_out[ 2 ] := 2;
			_out[ 3 ] := 3;

			e.SetXYZ( eR.z, eR.x, eR.y );
			basis.SetRows( rtx.rotation.ez, rtx.rotation.ex, rtx.rotation.ey );
		end

		else
		begin
			_out[ 0 ] := 4;
			_out[ 1 ] := 5;
			_out[ 2 ] := 6;
			_out[ 3 ] := 7;

			e.SetXYZ( eR.z, eR.x, eR.y );
			basis.SetRows( rtx.rotation.ez, -rtx.rotation.ex, -rtx.rotation.ey );
		end;

	  2:
		if n.z > 0.0 then
		begin
			_out[ 0 ] := 11;
			_out[ 1 ] := 4;
			_out[ 2 ] := 8;
			_out[ 3 ] := 0;

			e.SetXYZ( eR.y, eR.x, eR.z );
			basis.SetRows( -rtx.rotation.ey, rtx.rotation.ex, rtx.rotation.ez );
		end

		else
		begin
			_out[ 0 ] := 6;
			_out[ 1 ] := 10;
			_out[ 2 ] := 2;
			_out[ 3 ] := 9;

			e.SetXYZ( eR.y, eR.x, eR.z );
			basis.SetRows( -rtx.rotation.ey, -rtx.rotation.ex, -rtx.rotation.ez );
		end;
	end
end;

procedure q3ComputeIncidentFace( const itx: q3Transform; const e: q3Vec3; n: q3Vec3; _out: pq3ClipVertex );
begin
	n := -q3MulT( itx.rotation, n );
	var absN: q3Vec3 := n.Abs;

	if ( absN.x > absN.y ) and ( absN.x > absN.z ) then
	begin
		if n.x > 0.0 then
		begin
			_out[ 0 ].v.SetXYZ(  e.x,  e.y, -e.z );
			_out[ 1 ].v.SetXYZ(  e.x,  e.y,  e.z );
			_out[ 2 ].v.SetXYZ(  e.x, -e.y,  e.z );
			_out[ 3 ].v.SetXYZ(  e.x, -e.y, -e.z );

			_out[ 0 ].f.inI := 9;
			_out[ 0 ].f.outI := 1;
			_out[ 1 ].f.inI := 1;
			_out[ 1 ].f.outI := 8;
			_out[ 2 ].f.inI := 8;
			_out[ 2 ].f.outI := 7;
			_out[ 3 ].f.inI := 7;
			_out[ 3 ].f.outI := 9;
		end

		else
		begin
			_out[ 0 ].v.SetXYZ( -e.x, -e.y,  e.z );
			_out[ 1 ].v.SetXYZ( -e.x,  e.y,  e.z );
			_out[ 2 ].v.SetXYZ( -e.x,  e.y, -e.z );
			_out[ 3 ].v.SetXYZ( -e.x, -e.y, -e.z );

			_out[ 0 ].f.inI := 5;
			_out[ 0 ].f.outI := 11;
			_out[ 1 ].f.inI := 11;
			_out[ 1 ].f.outI := 3;
			_out[ 2 ].f.inI := 3;
			_out[ 2 ].f.outI := 10;
			_out[ 3 ].f.inI := 10;
			_out[ 3 ].f.outI := 5;
		end
	end

	else if ( absN.y > absN.x ) and ( absN.y > absN.z ) then
	begin
		if n.y > 0.0 then
		begin
			_out[ 0 ].v.SetXYZ( -e.x,  e.y,  e.z );
			_out[ 1 ].v.SetXYZ(  e.x,  e.y,  e.z );
			_out[ 2 ].v.SetXYZ(  e.x,  e.y, -e.z );
			_out[ 3 ].v.SetXYZ( -e.x,  e.y, -e.z );

			_out[ 0 ].f.inI := 3;
			_out[ 0 ].f.outI := 0;
			_out[ 1 ].f.inI := 0;
			_out[ 1 ].f.outI := 1;
			_out[ 2 ].f.inI := 1;
			_out[ 2 ].f.outI := 2;
			_out[ 3 ].f.inI := 2;
			_out[ 3 ].f.outI := 3;
		end

		else
		begin
			_out[ 0 ].v.SetXYZ(  e.x, -e.y,  e.z );
			_out[ 1 ].v.SetXYZ( -e.x, -e.y,  e.z );
			_out[ 2 ].v.SetXYZ( -e.x, -e.y, -e.z );
			_out[ 3 ].v.SetXYZ(  e.x, -e.y, -e.z );

			_out[ 0 ].f.inI := 7;
			_out[ 0 ].f.outI := 4;
			_out[ 1 ].f.inI := 4;
			_out[ 1 ].f.outI := 5;
			_out[ 2 ].f.inI := 5;
			_out[ 2 ].f.outI := 6;
			_out[ 3 ].f.inI := 5;
			_out[ 3 ].f.outI := 6;
		end
	end

	else
	begin
		if n.z > 0.0 then
		begin
			_out[ 0 ].v.SetXYZ( -e.x,  e.y,  e.z );
			_out[ 1 ].v.SetXYZ( -e.x, -e.y,  e.z );
			_out[ 2 ].v.SetXYZ(  e.x, -e.y,  e.z );
			_out[ 3 ].v.SetXYZ(  e.x,  e.y,  e.z );

			_out[ 0 ].f.inI := 0;
			_out[ 0 ].f.outI := 11;
			_out[ 1 ].f.inI := 11;
			_out[ 1 ].f.outI := 4;
			_out[ 2 ].f.inI := 4;
			_out[ 2 ].f.outI := 8;
			_out[ 3 ].f.inI := 8;
			_out[ 3 ].f.outI := 0;
		end

		else
		begin
			_out[ 0 ].v.SetXYZ(  e.x, -e.y, -e.z );
			_out[ 1 ].v.SetXYZ( -e.x, -e.y, -e.z );
			_out[ 2 ].v.SetXYZ( -e.x,  e.y, -e.z );
			_out[ 3 ].v.SetXYZ(  e.x,  e.y, -e.z );

			_out[ 0 ].f.inI := 9;
			_out[ 0 ].f.outI := 6;
			_out[ 1 ].f.inI := 6;
			_out[ 1 ].f.outI := 10;
			_out[ 2 ].f.inI := 10;
			_out[ 2 ].f.outI := 2;
			_out[ 3 ].f.inI := 2;
			_out[ 3 ].f.outI := 9;
		end
	end;

	for var i: i32 := 0 to 3 do
		_out[ i ].v := q3Mul( itx, _out[ i ].v );
end;

procedure q3EdgesContact( var CA, CB: q3Vec3; const PA, QA, PB, QB: q3Vec3 );
begin
	var DA: q3Vec3 := QA - PA;
	var DB: q3Vec3 := QB - PB;
	var r: q3Vec3 := PA - PB;
	var a: r32 := DA.Dot( DA );
	var e: r32 := DB.Dot( DB );
	var f: r32 := DB.Dot( r );
	var c: r32 := DA.Dot( r );

	var b: r32 := DA.Dot( DB );
	var denom: r32 := a * e - b * b;

	var TA: r32 := (b * f - c * e) / denom;
	var TB: r32 := (b * TA + f) / e;

	CA := PA + DA * TA;
	CB := PB + DB * TB;
end;

procedure q3SupportEdge( const tx: q3Transform; const e: q3Vec3; n: q3Vec3; var aOut, bOut: q3Vec3 );
begin
	n := q3MulT( tx.rotation, n );
	var absN: q3Vec3 := n.Abs;
	var a, b: q3Vec3;

	if absN.x > absN.y then
	begin
		if absN.y > absN.z then
		begin
			a.SetXYZ( e.x, e.y, e.z );
			b.SetXYZ( e.x, e.y, -e.z );
		end

		else
		begin
			a.SetXYZ( e.x, e.y, e.z );
			b.SetXYZ( e.x, -e.y, e.z );
		end;
	end

	else
	begin
		if absN.x > absN.z then
		begin
			a.SetXYZ( e.x, e.y, e.z );
			b.SetXYZ( e.x, e.y, -e.z );
		end

		else
		begin
			a.SetXYZ( e.x, e.y, e.z );
			b.SetXYZ( -e.x, e.y, e.z );
		end
	end;

	var signx: r32 := q3Sign( n.x );
	var signy: r32 := q3Sign( n.y );
	var signz: r32 := q3Sign( n.z );

	a.x := a.x * signx;
	a.y := a.y * signy;
	a.z := a.z * signz;
	b.x := b.x * signx;
	b.y := b.y * signy;
	b.z := b.z * signz;

	aOut := q3Mul( tx, a );
	bOut := q3Mul( tx, b );
end;

procedure q3BoxtoBox(var m: q3Manifold; a, b: pq3Box);
begin
	var atx: q3Transform := a.body.GetTransform( );
	var btx: q3Transform := b.body.GetTransform( );
	var aL: q3Transform := a.local;
	var bL: q3Transform := b.local;
	atx := q3Mul( atx, aL );
	btx := q3Mul( btx, bL );
	var eA: q3Vec3 := a.e;
	var eB: q3Vec3 := b.e;

	var C: q3Mat3 := atx.rotation.Transpose * btx.rotation;

	var absC: q3Mat3;
	var parallel: Boolean := false;
	const kCosTol = 1.0e-6;
	for var i:i32 := 0 to 2 do
	begin
		for var j: i32 := 0 to 2 do
		begin
			var val: r32 := Abs( C.v[ i ].v[ j ] );
			absC.v[ i ].v[ j ] := val;

			if val + kCosTol >= 1.0 then
				parallel := true;
		end;
	end;

	var t: q3Vec3 := q3MulT( atx.rotation, btx.position - atx.position );

	var s: r32;
	var aMax: r32 := -Q3_R32_MAX;
	var bMax: r32 := -Q3_R32_MAX;
	var eMax: r32 := -Q3_R32_MAX;
	var aAxis: i32 := not 0;
	var bAxis: i32 := not 0;
	var eAxis: i32 := not 0;
	var nA: q3Vec3;
	var nB: q3Vec3;
	var nE: q3Vec3;

	s := Abs( t.x ) - (eA.x + absC.Column0.Dot( eB ));
	if q3TrackFaceAxis( aAxis, 0, s, aMax, atx.rotation.ex, nA ) then
		Exit;

	s := Abs( t.y ) - (eA.y + absC.Column1.Dot( eB ));
	if q3TrackFaceAxis( aAxis, 1, s, aMax, atx.rotation.ey, nA ) then
		Exit;

	s := Abs( t.z ) - (eA.z + absC.Column2.Dot( eB ));
	if q3TrackFaceAxis( aAxis, 2, s, aMax, atx.rotation.ez, nA ) then
		Exit;

	// b's x axis
	s := Abs( t.Dot( C.ex ) ) - (eB.x + absC.ex.Dot( eA ));
	if q3TrackFaceAxis( bAxis, 3, s, bMax, btx.rotation.ex, nB) then
		Exit;

	// b's y axis
	s := Abs( t.Dot( C.ey ) ) - (eB.y + absC.ey.Dot( eA ));
	if q3TrackFaceAxis( bAxis, 4, s, bMax, btx.rotation.ey, nB ) then
		Exit;

	// b's z axis
	s := Abs( t.Dot( C.ez ) ) - (eB.z + absC.ez.Dot( eA ));
	if q3TrackFaceAxis( bAxis, 5, s, bMax, btx.rotation.ez, nB ) then
		Exit;

	if not parallel then
	begin
		// Edge axis checks
		var rA: r32;
		var rB: r32;

		// Cross( a.x, b.x )
		rA := eA.y * absC.v[ 0 ].v[ 2 ] + eA.z * absC.v[ 0 ].v[ 1 ];
		rB := eB.y * absC.v[ 2 ].v[ 0 ] + eB.z * absC.v[ 1 ].v[ 0 ];
		s := Abs( t.z * C.v[ 0 ].v[ 1 ] - t.y * C.v[ 0 ].v[ 2 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 6, s, eMax, q3Vec3.Create( 0.0, -C.v[ 0 ].v[ 2 ], C.v[ 0 ].v[ 1 ] ), nE ) then
			Exit;

		// Cross( a.x, b.y )
		rA := eA.y * absC.v[ 1 ].v[ 2 ] + eA.z * absC.v[ 1 ].v[ 1 ];
		rB := eB.x * absC.v[ 2 ].v[ 0 ] + eB.z * absC.v[ 0 ].v[ 0 ];
		s := Abs( t.z * C.v[ 1 ].v[ 1 ] - t.y * C.v[ 1 ].v[ 2 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 7, s, eMax, q3Vec3.Create( 0.0, -C.v[ 1 ].v[ 2 ], C.v[ 1 ].v[ 1 ] ), nE ) then
			Exit;

		// Cross( a.x, b.z )
		rA := eA.y * absC.v[ 2 ].v[ 2 ] + eA.z * absC.v[ 2 ].v[ 1 ];
		rB := eB.x * absC.v[ 1 ].v[ 0 ] + eB.y * absC.v[ 0 ].v[ 0 ];
		s := Abs( t.z * C.v[ 2 ].v[ 1 ] - t.y * C.v[ 2 ].v[ 2 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 8, s, eMax, q3Vec3.Create( 0.0, -C.v[ 2 ].v[ 2 ], C.v[ 2 ].v[ 1 ] ), nE ) then
			Exit;

		// Cross( a.y, b.x )
		rA := eA.x * absC.v[ 0 ].v[ 2 ] + eA.z * absC.v[ 0 ].v[ 0 ];
		rB := eB.y * absC.v[ 2 ].v[ 1 ] + eB.z * absC.v[ 1 ].v[ 1 ];
		s := Abs( t.x * C.v[ 0 ].v[ 2 ] - t.z * C.v[ 0 ].v[ 0 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 9, s, eMax, q3Vec3.Create( C.v[ 0 ].v[ 2 ], 0.0, -C.v[ 0 ].v[ 0 ] ), nE ) then
			Exit;

		// Cross( a.y, b.y )
		rA := eA.x * absC.v[ 1 ].v[ 2 ] + eA.z * absC.v[ 1 ].v[ 0 ];
		rB := eB.x * absC.v[ 2 ].v[ 1 ] + eB.z * absC.v[ 0 ].v[ 1 ];
		s := Abs( t.x * C.v[ 1 ].v[ 2 ] - t.z * C.v[ 1 ].v[ 0 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 10, s, eMax, q3Vec3.Create( C.v[ 1 ].v[ 2 ], 0.0 , -C.v[ 1 ].v[ 0 ] ), nE ) then
			Exit;

		// Cross( a.y, b.z )
		rA := eA.x * absC.v[ 2 ].v[ 2 ] + eA.z * absC.v[ 2 ].v[ 0 ];
		rB := eB.x * absC.v[ 1 ].v[ 1 ] + eB.y * absC.v[ 0 ].v[ 1 ];
		s := Abs( t.x * C.v[ 2 ].v[ 2 ] - t.z * C.v[ 2 ].v[ 0 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 11, s, eMax, q3Vec3.Create( C.v[ 2 ].v[ 2 ], 0.0, -C.v[ 2 ].v[ 0 ] ), nE ) then
			Exit;

		// Cross( a.z, b.x )
		rA := eA.x * absC.v[ 0 ].v[ 1 ] + eA.y * absC.v[ 0 ].v[ 0 ];
		rB := eB.y * absC.v[ 2 ].v[ 2 ] + eB.z * absC.v[ 1 ].v[ 2 ];
		s := Abs( t.y * C.v[ 0 ].v[ 0 ] - t.x * C.v[ 0 ].v[ 1 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 12, s, eMax, q3Vec3.Create( -C.v[ 0 ].v[ 1 ], C.v[ 0 ].v[ 0 ], 0.0 ), nE ) then
			Exit;

		// Cross( a.z, b.y )
		rA := eA.x * absC.v[ 1 ].v[ 1 ] + eA.y * absC.v[ 1 ].v[ 0 ];
		rB := eB.x * absC.v[ 2 ].v[ 2 ] + eB.z * absC.v[ 0 ].v[ 2 ];
		s := Abs( t.y * C.v[ 1 ].v[ 0 ] - t.x * C.v[ 1 ].v[ 1 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 13, s, eMax, q3Vec3.Create( -C.v[ 1 ].v[ 1 ], C.v[ 1 ].v[ 0 ], r32( 0.0 ) ), nE ) then
			Exit;

		// Cross( a.z, b.z )
		rA := eA.x * absC.v[ 2 ].v[ 1 ] + eA.y * absC.v[ 2 ].v[ 0 ];
		rB := eB.x * absC.v[ 1 ].v[ 2 ] + eB.y * absC.v[ 0 ].v[ 2 ];
		s := Abs( t.y * C.v[ 2 ].v[ 0 ] - t.x * C.v[ 2 ].v[ 1 ] ) - (rA + rB);
		if q3TrackEdgeAxis( eAxis, 14, s, eMax, q3Vec3.Create( -C.v[ 2 ].v[ 1 ], C.v[ 2 ].v[ 0 ], r32( 0.0 ) ), nE ) then
			Exit;
	end;

	// Artificial axis bias to improve frame coherence
	const kRelTol = 0.95;
	const kAbsTol = 0.01;
	var axis: i32;
	var sMax: r32;
	var n: q3Vec3;
	var faceMax: r32 := Max( aMax, bMax );
	if kRelTol * eMax > faceMax + kAbsTol then
	begin
		axis := eAxis;
		sMax := eMax;
		n := nE;
	end

	else
	begin
		if kRelTol * bMax > aMax + kAbsTol then
		begin
			axis := bAxis;
			sMax := bMax;
			n := nB;
		end

		else
		begin
			axis := aAxis;
			sMax := aMax;
			n := nA;
		end
	end;

	if n.Dot( btx.position - atx.position ) < 0.0 then
		n := -n;

	if axis = not 0  then
		Exit;

	if axis < 6 then
	begin
		var rtx: q3Transform;
		var itx: q3Transform;
		var eR: q3Vec3;
		var eI: q3Vec3;
		var flip: Boolean;

		if axis < 3 then
		begin
			rtx := atx;
			itx := btx;
			eR := eA;
			eI := eB;
			flip := false;
		end

		else
		begin
			rtx := btx;
			itx := atx;
			eR := eB;
			eI := eA;
			flip := true;
			n := -n;
		end;

		// Compute reference and incident edge information necessary for clipping
		var incident: array[0..3] of q3ClipVertex;
		q3ComputeIncidentFace( itx, eI, n, @incident );
		var clipEdges: array[0..3] of u8;
		var basis: q3Mat3;
		var e: q3Vec3;
		q3ComputeReferenceEdgesAndBasis( eR, rtx, n, axis, @clipEdges, basis, e );

		// Clip the incident face against the reference face side planes
		var _out: array[0..7] of q3ClipVertex;
		var depths: array[0..7] of r32;
		var outNum: i32;
		outNum := q3Clip( rtx.position, e, @clipEdges, basis, @incident, @_out, @depths );

		if outNum <> 0 then
		begin
			m.contactCount := outNum;
      if flip then
        m.normal := -n
      else
        m.normal := n;

			for var i: i32 := 0 to outNum - 1 do
			begin
				var cc: pq3Contact := @m.contacts[i];

				var pair: q3FeaturePair := _out[ i ].f;

				if flip then
				begin
					swap( pair.inI, pair.inR );
					swap( pair.outI, pair.outR );
				end;

				cc.fp := _out[ i ].f;
				cc.position := _out[ i ].v;
				cc.penetration := depths[ i ];
			end
		end
	end

	else
	begin
		n := atx.rotation * n;

		if n.Dot( btx.position - atx.position ) < 0.0 then
			n := -n;

		var PA, QA: q3Vec3;
		var PB, QB: q3Vec3;
		q3SupportEdge( atx, eA,  n, PA, QA );
		q3SupportEdge( btx, eB, -n, PB, QB );

		var CA, CB: q3Vec3;
		q3EdgesContact( CA, CB, PA, QA, PB, QB );

		m.normal := n;
		m.contactCount := 1;

		var cc: pq3Contact := @m.contacts;
		var pair: q3FeaturePair;
		pair.key := axis;
		cc.fp := pair;
		cc.penetration := sMax;
		cc.position := (CA + CB) * r32( 0.5 );
	end
end;

function InFront( a: r32 ): Boolean; inline;
begin
  Result :=a < 0.0;
end;

function Behind( a: r32 ): Boolean; inline;
begin
  Result := a >= 0.0;
end;

function _On( a: r32 ): Boolean; inline;
begin
	Result := ( a < 0.005 ) and ( a > - 0.005 );
end;

function q3Orthographic( sign, e: r32; axis, clipEdge: i32; _in: pq3ClipVertex; inCount: i32; _out: pq3ClipVertex ): i32;
begin
	var outCount: i32 := 0;
	var a: q3ClipVertex := _in[ inCount - 1 ];

	for var i: i32 := 0 to inCount - 1 do
	begin
		var b: q3ClipVertex := _in[ i ];

		var da: r32 := sign * a.v.v[ axis ] - e;
		var db: r32 := sign * b.v.v[ axis ] - e;

		var cv: q3ClipVertex;

		if ((InFront( da ) and InFront( db )) or _On( da ) or _On( db )) then
		begin
			assert( outCount < 8 );
			_out[ outCount ] := b; Inc(outCount);
		end

		else if InFront( da ) and Behind( db ) then
		begin
			cv.f := b.f;
			cv.v := a.v + (b.v - a.v) * (da / (da - db));
			cv.f.outR := clipEdge;
			cv.f.outI := 0;
			assert( outCount < 8 );
			_out[ outCount ] := cv; Inc(outCount);
		end

		else if Behind( da ) and InFront( db ) then
		begin
			cv.f := a.f;
			cv.v := a.v + (b.v - a.v) * (da / (da - db));
			cv.f.inR := clipEdge;
			cv.f.inI := 0;
			assert( outCount < 8 );
			_out[ outCount ] := cv; Inc(outCount);

			assert( outCount < 8 );
			_out[ outCount ] := b; Inc(outCount);
		end;

		a := b;
	end;

	Result := outCount;
end;

function q3Clip( const rPos, e: q3Vec3; clipEdges: pu8; const basis: q3Mat3; incident, outVerts: pq3ClipVertex; outDepths: pr32 ): i32;
begin
	var inCount: i32 := 4;
	var outCount: i32;
	var _in: array[0..7] of q3ClipVertex;
	var _out: array[0..7] of q3ClipVertex;

	for var i: i32 := 0 to 3 do
		_in[ i ].v := q3MulT( basis, incident[ i ].v - rPos );

	outCount := q3Orthographic( 1.0, e.x, 0, clipEdges[ 0 ], @_in, inCount, @_out );

	if outCount = 0 then
		Exit(0);

	inCount := q3Orthographic( 1.0, e.y, 1, clipEdges[ 1 ], @_out, outCount, @_in );

	if inCount = 0 then
		Exit(0);

	outCount := q3Orthographic( -1.0, e.x, 0, clipEdges[ 2 ], @_in, inCount, @_out );

	if outCount = 0 then
		Exit(0);

	inCount := q3Orthographic( -1.0, e.y, 1, clipEdges[ 3 ], @_out, outCount, @_in );

	outCount := 0;
	for var i: i32 := 0 to inCount - 1 do
	begin
		var d: r32 := _in[ i ].v.z - e.z;

		if d <= 0.0 then
		begin
			outVerts[ outCount ].v := basis * _in[ i ].v + rPos;
			outVerts[ outCount ].f := _in[ i ].f;
			outDepths[ outCount ] := d; Inc(outCount);
		end;
	end;

	assert( outCount <= 8 );

	Result := outCount;
end;

function q3MixRestitution( A, B:  pq3Box ): r32; inline;
begin
	REsult := Max( A.restitution, B.restitution );
end;

function q3MixFriction( A, B: pq3Box ): r32; inline;
begin
	Result := sqrt( A.friction * B.friction );
end;

procedure q3ContactConstraint.SolveCollision;
begin
  manifold.contactCount := 0;

	q3BoxtoBox( manifold, A, B );

	if manifold.contactCount > 0 then
	begin
		if ( m_flags and eColliding ) <> 0 then
			m_flags := m_flags or eWasColliding

		else
			m_flags := m_flags or eColliding;
	end

	else
	begin
		if ( m_flags and eColliding ) <> 0 then
		begin
			m_flags := m_flags and (not eColliding);
			m_flags := m_flags or eWasColliding;
		end

		else
			m_flags := m_flags and (not eWasColliding);
	end;
end;

constructor q3ContactManager.Create;
begin
  m_allocator := TContactConstraintAllocator.Create;
  m_broadphase := q3BroadPhase.Create(Self);
end;

destructor q3ContactManager.Destroy;
begin
  m_broadphase.Free;
  m_allocator.Free;
  inherited;
end;

procedure q3ContactManager.AddContact(A: pq3Box; B: pq3Box);
begin
  var bodyA: pq3Body := A.body;
  var bodyB: pq3Body := B.body;

  if not bodyA.CanCollide(bodyB) then
    Exit;

  var edge: pq3ContactEdge := A.body.m_contactList;
  while edge <> nil do
  begin
    if edge.other = bodyB then
    begin
      var shapeA: pq3Box := edge.constraint.A;
      var shapeB: pq3Box := edge.constraint.B;
      if (A = shapeA) and (B = shapeB) then
        Exit;
    end;
    edge := edge.next;
  end;

  var contact: pq3ContactConstraint := m_allocator.Allocate( );
	contact.A := A;
	contact.B := B;
	contact.bodyA := A.body;
	contact.bodyB := B.body;
	contact.manifold.SetPair( A, B );
	contact.m_flags := 0;
	contact.friction := q3MixFriction( A, B );
	contact.restitution := q3MixRestitution( A, B );
	contact.manifold.contactCount := 0;

	for var i: i32 := 0 to 7 do
		contact.manifold.contacts[ i ].warmStarted := 0;

	contact.prev := nil;
	contact.next := m_contactList;
	if m_contactList <> nil then
		m_contactList.prev := contact;
	m_contactList := contact;

	contact.edgeA.constraint := contact;
	contact.edgeA.other := bodyB;

	contact.edgeA.prev := nil;
	contact.edgeA.next := bodyA.m_contactList;
	if bodyA.m_contactList <> nil then
		bodyA.m_contactList.prev := @contact.edgeA;
	bodyA.m_contactList := @contact.edgeA;

	contact.edgeB.constraint := contact;
	contact.edgeB.other := bodyA;

	contact.edgeB.prev := nil;
	contact.edgeB.next := bodyB.m_contactList;
	if bodyB.m_contactList <> nil then
		bodyB.m_contactList.prev := @contact.edgeB;
	bodyB.m_contactList := @contact.edgeB;

	bodyA.SetToAwake( );
	bodyB.SetToAwake( );

	Inc(m_contactCount);
end;

procedure q3ContactManager.FindNewContacts;
begin
  m_broadphase.UpdatePairs;
end;

procedure q3ContactManager.RemoveContact( contact: pq3ContactConstraint  );
begin
	var A: pq3Body := contact.bodyA;
	var B: pq3Body := contact.bodyB;

	if contact.edgeA.prev <> nil then
		contact.edgeA.prev.next := contact.edgeA.next;

	if contact.edgeA.next <> nil then
		contact.edgeA.next.prev := contact.edgeA.prev;

	if @contact.edgeA = A.m_contactList then
		A.m_contactList := contact.edgeA.next;

	if contact.edgeB.prev <> nil then
		contact.edgeB.prev.next := contact.edgeB.next;

	if contact.edgeB.next <> nil then
		contact.edgeB.next.prev := contact.edgeB.prev;

	if @contact.edgeB = B.m_contactList then
		B.m_contactList := contact.edgeB.next;

	A.SetToAwake( );
	B.SetToAwake( );

	if contact.prev <> nil then
		contact.prev.next := contact.next;

	if contact.next <> nil then
		contact.next.prev := contact.prev;

	if contact = m_contactList then
		m_contactList := contact.next;

	Dec(m_contactCount);

	m_allocator.Release( contact );
end;

procedure q3ContactManager.RemoveContactsFromBody( body: pq3Body );
begin
	var edge: pq3ContactEdge := body.m_contactList;

	while edge <> nil do
	begin
		var next: pq3ContactEdge := edge.next;
		RemoveContact( edge.constraint );
		edge := next;
	end;
end;

procedure q3ContactManager.RemoveFromBroadphase( body: pq3Body );
begin
	var box: pq3Box := body.m_boxes;

	while box <> nil do
	begin
		m_broadphase.RemoveBox( box );
		box := box.next;
	end;
end;

procedure q3ContactManager.TestCollisions;
begin
	var constraint: pq3ContactConstraint := m_contactList;

	while constraint <> nil do
	begin
		var A: pq3Box := constraint.A;
		var B: pq3Box := constraint.B;
		var bodyA: pq3Body := A.body;
		var bodyB: pq3Body := B.body;

		constraint.m_flags := constraint.m_flags and (not q3ContactConstraint.eIsland);

		if (not bodyA.IsAwake ) and (not bodyB.IsAwake) then
		begin
			constraint := constraint.next;
			continue;
		end;

		if not bodyA.CanCollide( bodyB ) then
		begin
			var next: pq3ContactConstraint := constraint.next;
			RemoveContact( constraint );
			constraint := next;
			continue;
		end;

		// Check if contact should persist
		if not m_broadphase.TestOverlap( A.broadPhaseIndex, B.broadPhaseIndex ) then
		begin
			var next: pq3ContactConstraint := constraint.next;
			RemoveContact( constraint );
			constraint := next;
			continue;
		end;
		var manifold : pq3Manifold := @constraint.manifold;
		var oldManifold : q3Manifold := constraint.manifold;
		var ot0: q3Vec3 := oldManifold.tangentVectors[ 0 ];
		var ot1: q3Vec3 := oldManifold.tangentVectors[ 1 ];
		constraint.SolveCollision( );
		manifold.normal.ComputeBasis( manifold.tangentVectors[ 0 ], manifold.tangentVectors[ 1 ]);

		for var i: i32 := 0 to manifold.contactCount - 1 do
		begin
			var c: q3Contact := manifold.contacts[i];
			c.tangentImpulse[ 0 ] := 0.0;
      c.tangentImpulse[ 1 ] := 0.0;
      c.normalImpulse := 0.0 ;
			var oldWarmStart: u8 := c.warmStarted;
			c.warmStarted := 0;

			for var j: i32 := 0 to oldManifold.contactCount - 1 do
			begin
				var oc: pq3Contact := @oldManifold.contacts[j];
				if c.fp.key = oc.fp.key then
				begin
					c.normalImpulse := oc.normalImpulse;

					var friction: q3Vec3 := ot0 * oc.tangentImpulse[ 0 ] + ot1 * oc.tangentImpulse[ 1 ];
					c.tangentImpulse[ 0 ] := friction.Dot( manifold.tangentVectors[ 0 ] );
					c.tangentImpulse[ 1 ] := friction.Dot( manifold.tangentVectors[ 1 ] );
					c.warmStarted := Max( oldWarmStart, u8( oldWarmStart + 1 ) );
					break;
				end;
			end;
		end;

		if m_contactListener <> nil then
		begin
			var now_colliding: i32 := constraint.m_flags and q3ContactConstraint.eColliding;
			var was_colliding: i32 := constraint.m_flags and q3ContactConstraint.eWasColliding;

			if ( now_colliding <> 0) and ( was_colliding = 0 ) then
				m_contactListener.BeginContact( constraint )

			else if ( now_colliding = 0) and ( was_colliding <> 0 ) then
				m_contactListener.EndContact( constraint );
		end;

		constraint := constraint.next;
	end;
end;

procedure q3ContactManager.RenderContacts( render: q3Render );
begin
	var contact: pq3ContactConstraint := m_contactList;

	while contact <> nil do
	begin
		var m: pq3Manifold := @contact.manifold;

		if (contact.m_flags and q3ContactConstraint.eColliding) = 0 then
		begin
			contact := contact.next;
			continue;
		end;

		for var j: i32 := 0 to m.contactCount - 1 do
		begin
			var c: pq3Contact := @m.contacts[j];
			var blue: f32 := (255 - c.warmStarted) / 255.0;
			var red: f32 := 1.0 - blue;
			render.SetScale( 10.0, 10.0, 10.0 );
			render.SetPenColor( red, blue, blue );
			render.SetPenPosition( c.position.x, c.position.y, c.position.z );
			render.Point( );

			if m.A.body.IsAwake then
				render.SetPenColor( 1.0, 1.0, 1.0 )
			else
				render.SetPenColor( 0.2, 0.2, 0.2 );

			render.SetPenPosition( c.position.x, c.position.y, c.position.z );
			render.Line(
				c.position.x + m.normal.x * 0.5,
				c.position.y + m.normal.y * 0.5,
				c.position.z + m.normal.z * 0.5
				);
		end;

		contact := contact.next;
	end;

	render.SetScale( 1.0, 1.0, 1.0 );
end;

constructor q3Scene.Create();
begin
  Create(q3Vec3.Create(0.0, -9.8, 0.0));
end;

constructor q3Scene.Create(const gravity: q3Vec3);
begin
  m_contactManager := q3ContactManager.Create();
  m_boxAllocator := TBoxAllocator.Create;
  m_bodyAllocator := TBodyAllocator.Create;
  m_gravity := gravity;
  m_allowSleep := True;
  m_enableFriction := True;
end;

destructor q3Scene.Destroy;
begin
  Shutdown;
  m_boxAllocator.Free;
  m_bodyAllocator.Free;
  m_contactManager.Free;
end;

procedure q3Scene.Step( dt: r32; iterations: i32 );
begin
	if m_newBox then
	begin
		m_contactManager.m_broadphase.UpdatePairs( );
		m_newBox := false;
	end;

	m_contactManager.TestCollisions( );

  var body: pq3Body := m_bodyList;
  m_awakeCount := 0;
  while body <> nil do
  begin
		body.m_flags := body.m_flags and not q3Body.eIsland;
    if body.IsAwake then
      Inc(m_awakeCount);
    body := body.m_next;
  end;

  m_island.SetBodyCount(m_bodyCount);
  m_island.SetContactCount(m_contactManager.m_contactCount);
	m_island.m_allowSleep := m_allowSleep;
	m_island.m_enableFriction := m_enableFriction;
	m_island.m_bodyCount := 0;
	m_island.m_contactCount := 0;
	m_island.m_dt := dt;
	m_island.m_gravity := m_gravity;
	m_island.m_iterations := iterations;

  if Length(m_stack) < m_bodyCount then
    SetLength(m_stack, Max(16, Max(m_bodyCount, 2 * Length(m_stack))));

  m_islandCount := 0;
 
  var iseed: pq3Body := m_bodyList;
  while iseed <> nil do
  begin
    var seed: pq3Body := iseed;
    iseed := iseed.m_next;

		if seed.m_flags and q3Body.eIsland <> 0 then
			continue;

		if seed.m_flags and q3Body.eAwake = 0 then
			continue;

		if seed.m_flags and q3Body.eStatic <> 0 then
			continue;

		Inc(m_islandCount);
		var stackCount: i32 := 0;
		m_stack[ stackCount ] := seed; Inc(stackCount);
		m_island.m_bodyCount := 0;
		m_island.m_contactCount := 0;

		seed.m_flags := seed.m_flags or q3Body.eIsland;

		while stackCount > 0 do
		begin
      Dec(stackCount);
			body := m_stack[ stackCount ];
			m_island.Add( body );

			body.SetToAwake( );

			if body.m_flags and q3Body.eStatic <> 0 then
				continue;

			var contacts: pq3ContactEdge := body.m_contactList;
      var iedge: pq3ContactEdge := contacts;
			while iedge <> nil do
			begin
        var edge: pq3ContactEdge := iedge;
        iedge := iedge.next;

				var contact: pq3ContactConstraint := edge.constraint;

				if contact.m_flags and q3ContactConstraint.eIsland <> 0 then
					continue;

				if contact.m_flags and q3ContactConstraint.eColliding = 0 then
					continue;

				if contact.A.sensor or contact.B.sensor then
					continue;

				contact.m_flags := contact.m_flags or q3ContactConstraint.eIsland;
				m_island.Add( contact );

				var other: pq3Body := edge.other;
				if other.m_flags and q3Body.eIsland <> 0 then
					continue;

				assert( stackCount < m_bodyCount );

				m_stack[ stackCount ] := other; Inc(stackCount);
				other.m_flags := other.m_flags or q3Body.eIsland;
			end;
		end;

		assert( m_island.m_bodyCount <> 0 );

		m_island.Initialize( );
		m_island.Solve( );

		for var i: i32 := 0 to m_island.m_bodyCount - 1 do
		begin
			body := m_island.m_bodies[ i ];

			if body.m_flags and q3Body.eStatic <> 0 then
				body.m_flags := body.m_flags and not q3Body.eIsland;
		end;

	end;

  var ibody: pq3Body := m_bodyList;
	while ibody <> nil do
	begin
    body := ibody;
    ibody := ibody.m_next;

		if body.m_flags and q3Body.eStatic <> 0 then
			continue;

		body.SynchronizeProxies( );
	end;

	m_contactManager.FindNewContacts( );

  body := m_bodyList;
  while body <> nil do
	begin
		body.m_force.Identity;
		body.m_torque.Identity;
    body := body.m_next;
	end;

end;

function q3Scene.CreateBody(const def: q3BodyDef): pq3Body;
begin
	var body: pq3Body := m_bodyAllocator.Allocate( );
	body.Create( def, Self );

	// Add body to scene bodyList
	body.m_prev := nil;
	body.m_next := m_bodyList;

	if m_bodyList <> nil then
		m_bodyList.m_prev := body;

	m_bodyList := body;
	Inc(m_bodyCount);

  if body.IsAwake then
    Inc(m_awakeCount);

	Result := body;
end;

procedure q3Scene.RemoveBody( body: pq3Body );
begin
  assert( m_bodyCount > 0 );
  m_contactManager.RemoveContactsFromBody( body );
  body.RemoveAllBoxes();
  if body.m_next <> nil then
		body.m_next.m_prev := body.m_prev;

	if body.m_prev <> nil then
		body.m_prev.m_next := body.m_next;

	if body = m_bodyList then
		m_bodyList := body.m_next;

	Dec(m_bodyCount);

	m_bodyAllocator.Release( body );
end;

procedure q3Scene.RemoveAllBodies;
begin
	var body: pq3Body := m_bodyList;

	while m_bodyList <> nil do
	begin
    RemoveBody(m_bodyList);
	end;

  m_stack := nil;
  m_island.Clear;
  m_boxAllocator.Clear;
  m_bodyAllocator.Clear;
end;

procedure q3Scene.SetAllowSleep(allowSleep: Boolean);
begin
  m_allowSleep := allowSleep;
  if not allowSleep then
  begin
    var body: pq3Body := m_bodyList;
    while body <> nil do
    begin
      body.SetToAwake;
      body := body.m_next;
    end;
  end;
end;

procedure q3Scene.SetIterations(iterations: i32);
begin
  m_base_iterations := Max(1, iterations);
end;

procedure q3Scene.SetEnableFriction(enabled: Boolean);
begin
  m_enableFriction := enabled;
end;

procedure q3Scene.Render(render: q3Render);
begin
  var body: pq3Body := m_bodyList;
  while body <> nil do
  begin
    body.Render( render, m_showLinks);
    body := body.m_next;
  end;
  if m_showContact then
    m_contactManager.RenderContacts( render );
  if m_showAABB then
    m_contactManager.m_broadphase.m_tree.Render( render );
end;

function q3Scene.GetGravity: q3Vec3;
begin
  Result := m_gravity;
end;

procedure q3Scene.SetGravity(const gravity: q3Vec3);
begin
  m_gravity := gravity;
end;

procedure q3Scene.Shutdown;
begin
  RemoveAllBodies();
end;

procedure q3Scene.SetContactListener(listener: q3ContactListener);
begin
  m_contactManager.m_contactListener := listener;
end;

type
  SceneQueryAABBWrapper = record
    cb: q3ReportShape;
    broadPhase: q3BroadPhase;
    m_aabb: q3AABB;
    function TreeCallBack(id: i32): Boolean;
  end;

function SceneQueryAABBWrapper.TreeCallBack(id: i32): Boolean;
begin
  var aabb: q3AABB;
  var box: pq3Box := broadPhase.m_tree.GetUserData(id);
  box.ComputeAABB(box.body.GetTransform, aabb);
  if m_aabb.AABBtoAABB( aabb) then
    Exit(cb(box));
  Result := True;
end;

procedure q3Scene.QueryAABB(cb: q3ReportShape; const aabb: q3AABB);
begin
  var wrapper: SceneQueryAABBWrapper;
  wrapper.m_aabb := aabb;
  wrapper.broadPhase := @m_contactManager.m_broadphase;
  wrapper.cb := cb;
  m_contactManager.m_broadphase.m_tree.Query(wrapper.TreeCallBack, aabb);
end;

type
  SceneQueryPointWrapper = record
    cb: q3ReportShape;
    broadPhase: q3BroadPhase;
    m_point: q3Vec3;
    function TreeCallBack(id: i32): Boolean;
  end;

function SceneQueryPointWrapper.TreeCallBack(id: i32): Boolean;
begin
  var box: pq3Box := broadPhase.m_tree.GetUserData(id);
  if box.TestPoint(box.body.GetTransform, m_point) then
    cb(box);
  Result := True;
end;

procedure q3Scene.QueryPoint(cb: q3ReportShape; const point: q3Vec3);
begin
  var wrapper: SceneQueryPointWrapper;
  wrapper.m_point := point;
  wrapper.broadPhase := m_contactManager.m_broadphase;
  wrapper.cb := cb;
  const k_fattener = 0.5;
  var v: q3Vec3 := q3Vec3.Create(k_fattener, k_fattener, k_fattener);
  var aabb: q3AABB;
  aabb.min := point - v;
  aabb.max := point + v;
  m_contactManager.m_broadphase.m_tree.Query(wrapper.TreeCallBack, aabb);
end;

type
  SceneQueryWrapper = record
    cb: q3ReportShape;
    broadPhase: q3BroadPhase;
    m_rayCast: pq3RaycastData;
    function TreeCallBack(id: i32): Boolean;
  end;

function SceneQueryWrapper.TreeCallBack(id: i32): Boolean;
begin
  var box: pq3Box := broadPhase.m_tree.GetUserData(id);
  if box.Raycast(box.body.GetTransform, m_rayCast) then
    Result := cb(box)
  else
    Result := True;
end;

procedure q3Scene.RayCast(cb: q3ReportShape; const rayCast: q3RaycastData);
begin
  var wrapper : SceneQueryWrapper;
  wrapper.m_rayCast := @rayCast;
  wrapper.broadPhase := m_contactManager.m_broadphase;
  wrapper.cb := cb;
  m_contactManager.m_broadphase.m_tree.Query(wrapper.TreeCallBack, rayCast);
end;

procedure q3ContactSolver.Initialize(island: pq3Island);
begin
  m_island := island;
  m_contactCount := island.m_contactCount;
  m_contacts := Pointer(island.m_contactStates);
  m_velocities := Pointer(m_island.m_velocities);
  m_enableFriction := island.m_enableFriction;
end;

procedure q3ContactSolver.ShutDown;
begin
  for var i: i32 := 0 to m_contactCount - 1 do
	begin
		var c: pq3ContactConstraintState := @m_contacts[ i ];
		var cc: pq3ContactConstraint := m_island.m_contacts[ i ];

		for var j: i32 := 0 to c.contactCount - 1 do
		begin
			var oc: pq3Contact := @cc.manifold.contacts[ j ];
			var cs: pq3ContactState := @c.contacts[ j ];
			oc.normalImpulse := cs.normalImpulse;
			oc.tangentImpulse[ 0 ] := cs.tangentImpulse[ 0 ];
			oc.tangentImpulse[ 1 ] := cs.tangentImpulse[ 1 ];
		end;
	end;
end;

procedure q3ContactSolver.PreSolve(dt: r32);
begin
  for var i: i32 := 0 to m_contactCount - 1 do
	begin
		var cs: pq3ContactConstraintState := @m_contacts[ i ];

		var vA: pq3Vec3 := @m_velocities[ cs.indexA ].v;
		var wA: pq3Vec3 := @m_velocities[ cs.indexA ].w;
		var vB: pq3Vec3 := @m_velocities[ cs.indexB ].v;
		var wB: pq3Vec3 := @m_velocities[ cs.indexB ].w;

		for var j: i32 := 0 to cs.contactCount - 1 do
		begin
			var c: pq3ContactState := @cs.contacts[ j ];

			var raCn: q3Vec3 := c.ra.Cross( cs.normal );
			var rbCn: q3Vec3 := c.rb.Cross( cs.normal );
			var nm: r32 := cs.mA + cs.mB;
			var tm: array [ 0..1 ] of r32;
			tm[ 0 ] := nm;
			tm[ 1 ] := nm;

			nm := nm + raCn.Dot( cs.iA * raCn ) + rbCn.Dot( cs.iB * rbCn );
			c.normalMass := q3Invert( nm );

			for var ii: i32 := 0 to 1 do
			begin
				var raCt: q3Vec3 := cs.tangentVectors[ ii ].Cross( c.ra );
				var rbCt: q3Vec3 := cs.tangentVectors[ ii ].Cross( c.rb );
				tm[ ii ] := tm[ ii ] + raCt.Dot( cs.iA * raCt ) + rbCt.Dot( cs.iB * rbCt );
				c.tangentMass[ ii ] := q3Invert( tm[ ii ] );
			end;

			// Precalculate bias factor
			c.bias := -Q3_BAUMGARTE * (r32( 1.0 ) / dt) * Min( 0.0, c.penetration + Q3_PENETRATION_SLOP );

			// Warm start contact
			var P: q3Vec3 := cs.normal * c.normalImpulse;

			if m_enableFriction then
			begin
				P := P + cs.tangentVectors[ 0 ] * c.tangentImpulse[ 0 ];
				P := P + cs.tangentVectors[ 1 ] * c.tangentImpulse[ 1 ];
			end;

			vA^ := vA^ - P * cs.mA;
			wA^ := wA^ - cs.iA * c.ra.Cross( P );

			vB^ := vB^ + P * cs.mB;
			wB^ := wB^ + cs.iB * c.rb.Cross( P );

			var dv: r32 := ( vB^ + wB.Cross( c.rb ) - vA^ - wA.Cross( c.ra ) ).Dot( cs.normal );

			if dv < -1.0 then
				c.bias := c.bias -(cs.restitution) * dv;
		end;

//		m_velocities[ cs.indexA ].v := vA;
//		m_velocities[ cs.indexA ].w := wA;
//		m_velocities[ cs.indexB ].v := vB;
//		m_velocities[ cs.indexB ].w := wB;
	end;
end;

procedure q3ContactSolver.Solve;
begin
	for var i: i32 := 0 to m_contactCount - 1 do
	begin
		var cs: pq3ContactConstraintState := @m_contacts[ i ];

		var vA: pq3Vec3 := @m_velocities[ cs.indexA ].v;
		var wA: pq3Vec3 := @m_velocities[ cs.indexA ].w;
		var vB: pq3Vec3 := @m_velocities[ cs.indexB ].v;
		var wB: pq3Vec3 := @m_velocities[ cs.indexB ].w;

		for var j: i32 := 0 to cs.contactCount - 1 do
		begin
			var c: pq3ContactState := @cs.contacts[ j ];

			var dv: q3Vec3 := vB^ + wB.Cross( c.rb ) - vA^ - wA.Cross( c.ra );

			if m_enableFriction then
			begin
				for var ii: i32 := 0 to 1 do
				begin
					var lambda: r32 := - dv.Dot( cs.tangentVectors[ ii ] ) * c.tangentMass[ ii ];

					var maxLambda: r32 := cs.friction * c.normalImpulse;

					var oldPT: r32 := c.tangentImpulse[ ii ];
					c.tangentImpulse[ ii ] := q3Clamp( -maxLambda, maxLambda, oldPT + lambda );
					lambda := c.tangentImpulse[ ii ] - oldPT;

					// Apply friction impulse
					var impulse: q3Vec3 := cs.tangentVectors[ ii ] * lambda;
					vA^  := vA^ - impulse * cs.mA;
					wA^ := wA^  - cs.iA * c.ra.Cross( impulse );

					vB^ := vB^ + impulse * cs.mB;
					wB^ := wB^ + cs.iB * c.rb.Cross( impulse );
				end;
			end;

			// Normal
			begin
				dv := vB^ + wB.Cross( c.rb ) - vA^ - wA.Cross( c.ra );

				// Normal impulse
				var vn: r32 := dv.Dot( cs.normal );

				// Factor in positional bias to calculate impulse scalar j
				var lambda: r32 := c.normalMass * (-vn + c.bias);

				// Clamp impulse
				var tempPN: r32 := c.normalImpulse;
				c.normalImpulse := Max( tempPN + lambda, r32( 0.0 ) );
				lambda := c.normalImpulse - tempPN;

				// Apply impulse
				var impulse: q3Vec3 := cs.normal * lambda;
				vA^ := vA^ - impulse * cs.mA;
				wA^ := wA^ - cs.iA * c.ra.Cross( impulse );

				vB^ := vB^ + impulse * cs.mB;
				wB^ := wB^ + cs.iB * c.rb.Cross( impulse );
			end;
		end;

//		m_velocities[ cs.indexA ].v := vA;
//		m_velocities[ cs.indexA ].w := wA;
//		m_velocities[ cs.indexB ].v := vB;
//		m_velocities[ cs.indexB ].w := wB;
	end;
end;

procedure q3Transform.Identity;
begin
  position.Identity;
  rotation.Identity;
end;

procedure q3Island.SetBodyCount(count: i32);
begin
  if count <= m_bodyCapacity then
    Exit;
  m_bodyCapacity := Max(16, Max(count, 2 * m_bodyCapacity));
  SetLength(m_bodies, m_bodyCapacity );
  SetLength(m_velocities, m_bodyCapacity);
end;

procedure q3Island.SetContactCount(count: i32);
begin
  if count <= m_contactCapacity then
    Exit;
  m_contactCapacity := Max(16, Max(count, 2 * m_contactCapacity));
  SetLength(m_contacts, m_contactCapacity);
  SetLength(m_contactStates, m_contactCapacity);
end;

procedure q3Island.Clear;
begin
  m_bodyCapacity := 0;
  m_contactCapacity := 0;
  m_bodies := nil;
  m_bodyCapacity := 0;
  m_velocities := nil;
  m_contacts := nil;
  m_contactCapacity := 0;
  m_contactStates := nil;
end;

procedure q3Island.Solve;
begin
	for var i: i32 := 0 to m_bodyCount - 1 do
	begin
		var body: pq3Body := m_bodies[ i ];
		var v: pq3VelocityState := @m_velocities[ i ];

		if body.m_flags and q3Body.eDynamic <> 0 then
		begin
			body.ApplyLinearForce( m_gravity * body.m_gravityScale );

			var r: q3Mat3 := body.m_tx.rotation;
			body.m_invInertiaWorld := r * body.m_invInertiaModel * r.Transpose;

			body.m_linearVelocity := body.m_linearVelocity + (body.m_force * body.m_invMass) * m_dt;
			body.m_angularVelocity := body.m_angularVelocity + (body.m_invInertiaWorld * body.m_torque) * m_dt;

			body.m_linearVelocity := body.m_linearVelocity * r32( 1.0 ) / (r32( 1.0 ) + m_dt * body.m_linearDamping);
			body.m_angularVelocity := body.m_angularVelocity * r32( 1.0 ) / (r32( 1.0 ) + m_dt * body.m_angularDamping);
		end;

		v.v := body.m_linearVelocity;
		v.w := body.m_angularVelocity;
	end;

	// Create contact solver, pass in state buffers, create buffers for contacts
	// Initialize velocity constraint for normal + friction and warm start
	var contactSolver: q3ContactSolver;
	contactSolver.Initialize( @Self );
	contactSolver.PreSolve( m_dt );

	// Solve contacts
	for var i: i32 := 0 to m_iterations - 1 do
		contactSolver.Solve( );

	contactSolver.ShutDown( );

	// Copy back state buffers
	// Integrate positions
	for var i: i32 := 0 to m_bodyCount - 1 do
	begin
		var body: pq3Body := m_bodies[ i ];
		var v: pq3VelocityState := @m_velocities[ i ];

		if body.m_flags and q3Body.eStatic <> 0 then
			continue;

		body.m_linearVelocity := v.v;
		body.m_angularVelocity := v.w;

		body.m_worldCenter := body.m_worldCenter + body.m_linearVelocity * m_dt;
		body.m_q.Integrate( body.m_angularVelocity, m_dt );
		body.m_tx.rotation := body.m_q.ToMat3( );
	end;

	if m_allowSleep then
	begin
		// Find minimum sleep time of the entire island
		var minSleepTime: f32 := Q3_R32_MAX;
		for var i: i32:= 0 to m_bodyCount - 1 do
		begin
			var body: pq3Body := m_bodies[ i ];

			if body.m_flags and q3Body.eStatic <>  0 then
				continue;

			var sqrLinVel: r32 := body.m_linearVelocity.Dot( body.m_linearVelocity );
			var cbAngVel: r32 := body.m_angularVelocity.Dot( body.m_angularVelocity );
			var linTol: r32 := Q3_SLEEP_LINEAR;
			var angTol: r32 := Q3_SLEEP_ANGULAR;

			if ( sqrLinVel > linTol) or (cbAngVel > angTol ) then
			begin
				minSleepTime := r32( 0.0 );
				body.m_sleepTime := r32( 0.0 );
			end

			else
			begin
				body.m_sleepTime := body.m_sleepTime + m_dt;
				minSleepTime := Min( minSleepTime, body.m_sleepTime );
			end;

		end;

		// Put entire island to sleep so long as the minimum found sleep time
		// is below the threshold. If the minimum sleep time reaches below the
		// sleeping threshold, the entire island will be reformed next step
		// and sleep test will be tried again.

		if minSleepTime > Q3_SLEEP_TIME then
		begin
			for var i: i32 := 0 to m_bodyCount - 1 do
				m_bodies[ i ].SetToSleep( );
		end;
	end;
end;

procedure q3Island.Add(body: pq3Body);
begin
	assert( m_bodyCount <= m_bodyCapacity );

	body.m_islandIndex := m_bodyCount;

	m_bodies[ m_bodyCount ] := body; Inc(m_bodyCount);
end;

procedure q3Island.Add(contact: pq3ContactConstraint);
begin
	assert( m_contactCount < m_contactCapacity );

	m_contacts[ m_contactCount ] := contact; Inc(m_contactCount);
end;

procedure q3Island.Initialize;
begin
  for var i: i32 := 0 to m_contactCount - 1 do
	begin
		var cc: pq3ContactConstraint := m_contacts[ i ];

		var c: pq3ContactConstraintState := @m_contactStates[ i ];

		c.centerA := cc.bodyA.m_worldCenter;
		c.centerB := cc.bodyB.m_worldCenter;
		c.iA := cc.bodyA.m_invInertiaWorld;
		c.iB := cc.bodyB.m_invInertiaWorld;
		c.mA := cc.bodyA.m_invMass;
		c.mB := cc.bodyB.m_invMass;
		c.restitution := cc.restitution;
		c.friction := cc.friction;
		c.indexA := cc.bodyA.m_islandIndex;
		c.indexB := cc.bodyB.m_islandIndex;
		c.normal := cc.manifold.normal;
		c.tangentVectors[ 0 ] := cc.manifold.tangentVectors[ 0 ];
		c.tangentVectors[ 1 ] := cc.manifold.tangentVectors[ 1 ];
		c.contactCount := cc.manifold.contactCount;

		for var j: i32 := 0 to c.contactCount - 1 do
		begin
			var s: pq3ContactState := @c.contacts[ j ];
			var cp: pq3Contact := @cc.manifold.contacts[ j ];
			s.ra := cp.position - c.centerA;
			s.rb := cp.position - c.centerB;
			s.penetration := cp.penetration;
			s.normalImpulse := cp.normalImpulse;
			s.tangentImpulse[ 0 ] := cp.tangentImpulse[ 0 ];
			s.tangentImpulse[ 1 ] := cp.tangentImpulse[ 1 ];
		end;
	end;
end;

class operator q3BodyDef.Initialize(out def: q3BodyDef);
begin
  FillChar(def, SizeOf(def), 0);
  def.axis.Identity;
  def.angle := 0.0;
  def.position.Identity;
  def.linearVelocity.Identity;
  def.angularVelocity.Identity;
  def.gravityScale := 1.0;
  def.bodyType := eStaticBody;
  def.layers := $00000001;
  def.userData := nil;
  def.allowSleep := true;
  def.awake := true;
  def.active := true;
  def.lockAxisX := false;
  def.lockAxisY := false;
  def.lockAxisZ := false;
  def.linearDamping := 0.0;
  def.angularDamping := 0.1;
end;

constructor q3Body.Create(const def: q3BodyDef; scene: q3Scene);
begin
  m_linearVelocity := def.linearVelocity;
	m_angularVelocity := def.angularVelocity;
	m_force.Identity;
	m_torque.Identity;
	m_q.Create( def.axis.Normalize , def.angle );
	m_tx.rotation := m_q.ToMat3( );
	m_tx.position := def.position;
	m_sleepTime := 0.0;
	m_gravityScale := def.gravityScale;
	m_layers := def.layers;
	m_userData := def.userData;
	m_scene := scene;
	m_flags := 0;
	m_linearDamping := def.linearDamping;
	m_angularDamping := def.angularDamping;

	if def.bodyType = eDynamicBody then
		m_flags := m_flags or q3Body.eDynamic

	else
	begin
		if def.bodyType = eStaticBody then
		begin
			m_flags := m_flags or q3Body.eStatic;
			m_linearVelocity.Identity;
			m_angularVelocity.Identity;
			m_force.Identity;
			m_torque.Identity;
		end

		else if def.bodyType = eKinematicBody then
			m_flags := m_flags or q3Body.eKinematic;
	end;

	if def.allowSleep then
		m_flags := m_flags or eAllowSleep;

	if def.awake then
		m_flags := m_flags or eAwake;

	if def.active then
		m_flags := m_flags or eActive;

	if def.lockAxisX then
		m_flags := m_flags or eLockAxisX;

	if def.lockAxisY then
		m_flags := m_flags or eLockAxisY;

	if def.lockAxisZ then
		m_flags := m_flags or eLockAxisZ;

	m_boxes := nil;
	m_contactList := nil;
end;

function q3Body.AddBox( const def: q3BoxDef ): pq3Box;
begin
	var aabb: q3AABB;
	var box: pq3Box := m_scene.m_boxAllocator.Allocate;
	box.local := def.m_tx;
	box.e := def.m_e;
	box.next := m_boxes;
	m_boxes := box;
	box.ComputeAABB( m_tx, aabb );

	box.body := @Self;
	box.friction := def.m_friction;
	box.restitution := def.m_restitution;
	box.density := def.m_density;
	box.sensor := def.m_sensor;

	CalculateMassData( );

	m_scene.m_contactManager.m_broadphase.InsertBox( box, aabb );
	m_scene.m_newBox := true;

	Result := box;
end;

procedure q3Body.RemoveBox( box: pq3Box );
begin
	assert( box <> nil );
	assert( box.body = @Self );

	var node: pq3Box := m_boxes;

	var found: Boolean := false;
	if node = box then
	begin
		m_boxes := node.next;
		found := true;
	end

	else
	begin
		while node <> nil do
		begin
			if node.next = box then
			begin
				node.next := box.next;
				found := true;
				break;
			end;

			node := node.next;
		end;
	end;

	assert( found );

	var edge: pq3ContactEdge := m_contactList;
	while edge <> nil do
	begin
		var contact: pq3ContactConstraint := edge.constraint;
		edge := edge.next;

		var A: pq3Box := contact.A;
		var B: pq3Box := contact.B;

		if ( box = A ) or ( box = B ) then
			m_scene.m_contactManager.RemoveContact( contact );
	end;

	m_scene.m_contactManager.m_broadphase.RemoveBox( box );

	CalculateMassData( );

	m_scene.m_boxAllocator.Release( box );
end;

procedure q3Body.RemoveAllBoxes;
begin
  while m_boxes <> nil do
  begin
    var next : pq3Box := m_boxes.next;
    m_scene.m_contactManager.m_broadphase.RemoveBox(m_boxes);
    m_scene.m_boxAllocator.Release(m_boxes);
    m_boxes := next;
  end;
  m_scene.m_contactManager.RemoveContactsFromBody(@Self);
end;

procedure q3Body.ApplyLinearForce(const force: q3Vec3);
begin
  m_force := m_force + force * m_mass;
  SetToAwake();
end;

procedure q3Body.ApplyForceAtWorldPoint(const force: q3Vec3; const point: q3Vec3);
begin
  m_force := m_force + force * m_mass;
  m_torque := m_torque + (point - m_worldCenter).Cross( force );
  SetToAwake();
end;

procedure q3Body.ApplyLinearImpulse(const impulse: q3Vec3);
begin
  m_linearVelocity := m_linearVelocity + impulse * m_invMass;
  SetToAwake();
end;

procedure q3Body.ApplyLinearImpulseAtWorldPoint(const impulse: q3Vec3; const point: q3Vec3);
begin
  m_linearVelocity := m_linearVelocity + impulse * m_invMass;
  m_angularVelocity := m_angularVelocity + m_invInertiaWorld * ( point - m_worldCenter).Cross( impulse );
  SetToAwake();
end;

procedure q3Body.ApplyTorque(const torque: q3Vec3);
begin
  m_torque := m_torque + torque;
end;

procedure q3Body.SetToAwake;
begin
  if m_flags and eAwake = 0 then
  begin
    m_flags := m_flags or eAwake;
    m_sleepTime := 0.0;
  end;
end;

procedure q3Body.SetToSleep;
begin
  m_flags := m_flags and not eAwake;
  m_sleepTime := 0.0;
  m_linearVelocity.Identity;
	m_angularVelocity.Identity;
	m_force.Identity;
	m_torque.Identity;
end;

function q3Body.IsAwake: Boolean;
begin
  Result := m_flags and eAwake <> 0;
end;

function q3Body.GetMass: r32;
begin
  Result := m_mass;
end;

function q3Body.GetInvMass: r32;
begin
  Result := m_invMass;
end;

function q3Body.GetGravityScale: r32;
begin
  Result := m_gravityScale;
end;

procedure q3Body.SetGravityScale(scale: r32);
begin
  m_gravityScale := scale;
end;

function q3Body.GetLocalPoint(const p: q3Vec3): q3Vec3;
begin
  Result := q3MulT(m_tx, p);
end;

function q3Body.GetLocalVector(const v: q3Vec3): q3Vec3;
begin
  Result := q3MulT(m_tx.rotation, v);
end;

function q3Body.GetWorldPoint(const p: q3Vec3): q3Vec3;
begin
  Result := q3Mul(m_tx, p);
end;

function q3Body.GetWorldVector(const v: q3Vec3): q3Vec3;
begin
  Result := m_tx.rotation * v;
end;

function q3Body.GetLinearVelocity: q3Vec3;
begin
  Result := m_linearVelocity;
end;

function q3Body.GetVelocityAtWorldPoint(const p: q3Vec3): q3Vec3;
begin
  var directionToPoint: q3Vec3 := p - m_worldCenter;
  var relativeAngularVel: q3Vec3 := m_angularVelocity.Cross( directionToPoint );
  Result := m_linearVelocity + relativeAngularVel;
end;

procedure q3Body.SetLinearVelocity(const v: q3Vec3);
begin
  if m_flags and eStatic <> 0 then
    assert(false);
  if v.Dot( v ) > Epsilon then
  begin
    SetToAwake;
  end;
  m_linearVelocity := v;
end;

function q3Body.GetAngularVelocity: q3Vec3;
begin
  Result := m_angularVelocity;
end;

procedure q3Body.SetAngularVelocity(const v: q3Vec3);
begin
  if m_flags and eStatic <> 0 then
    assert(false);
  if v.Dot( v ) > Epsilon then
  begin
    SetToAwake;
  end;
  m_angularVelocity := v;
end;

function q3Body.CanCollide(other: pq3Body): Boolean;
begin
  if @Self = other then
    Exit(False);
  if (m_flags and eDynamic = 0) and (other.m_flags and eDynamic = 0) then
    Exit(False);
  if m_layers and other.m_layers = 0 then
    Exit(False);
  Result := True;
end;

function q3Body.GetTransform: q3Transform;
begin
  Result := m_tx;
end;

procedure q3Body.SetTransform(const position: q3Vec3);
begin
  m_worldCenter := position;
  SynchronizeProxies;
end;

procedure q3Body.SetTransform(const position: q3Vec3; const axis: q3Vec3; angle: r32);
begin
  m_worldCenter := position;
  m_q.Create(axis, angle);
  m_tx.rotation := m_q.ToMat3;
  SynchronizeProxies;
end;

function q3Body.GetFlags: i32;
begin
  Result := m_flags;
end;

procedure q3Body.SetLayers(layers: i32);
begin
  m_layers := layers;
end;

function q3Body.GetLayers: i32;
begin
  Result := m_layers;
end;

function q3Body.GetQuaternion: q3Quaternion;
begin
  Result := m_q;
end;

function q3Body.GetUserData: Pointer;
begin
  Result := m_userData;
end;

procedure q3Body.SetLinearDamping(damping: r32);
begin
  m_linearDamping := damping;
end;

function q3Body.GetLinearDamping(damping: r32): r32;
begin
  Result := m_linearDamping;
end;

procedure q3Body.SetAngularDamping(damping: r32);
begin
  m_angularDamping := damping;
end;

function q3Body.GetAngularDamping(damping: r32): r32;
begin
  Result := m_angularDamping;
end;

procedure q3Body.Render(render: q3Render; showLinks: Boolean);
begin
  var awake :=  m_flags and (eStatic or eAwake) = eAwake;
  var box: pq3Box := m_boxes;
  while box <> nil do
  begin
    box.Render(m_tx, awake, render, showLinks);
    box := box.next;
  end;
end;

procedure q3Body.CalculateMassData;
begin
	var inertia := q3Mat3.Diagonal1( 0.0 );
	m_invInertiaModel := q3Mat3.Diagonal1( 0.0 );
	m_invInertiaWorld := q3Mat3.Diagonal1( 0.0 );
	m_invMass := r32( 0.0 );
	m_mass := r32( 0.0 );
	var mass: r32 := r32( 0.0 );

	if ( m_flags and eStatic <> 0) or (m_flags and eKinematic <> 0) then
	begin
		m_localCenter.Identity;
		m_worldCenter := m_tx.position;
		Exit;
	end;

	var lc: q3Vec3;
	lc.Identity;

  var ibox: pq3Box := m_boxes;
  while ibox <> nil do
  begin
    var box: pq3Box := ibox;
    ibox := ibox.next;

		if box.density = 0.0 then
			continue;

		var md: q3MassData;
		box.ComputeMass( md );
		mass := mass + md.mass;
		inertia := inertia + md.inertia;
		lc := lc + md.center * md.mass;
	end;

	if mass > r32( 0.0 ) then
	begin
		m_mass := mass;
		m_invMass := r32( 1.0 ) / mass;
		lc := lc * m_invMass;
		var identity: q3Mat3;
		identity.Identity;
		inertia := inertia - (identity * lc.Dot( lc ) - lc.OuterProduct( lc )) * mass;
		m_invInertiaModel := inertia.Inverse;

		if m_flags and eLockAxisX <> 0 then
			m_invInertiaModel.ex.Identity;;

    if m_flags and eLockAxisY <> 0 then
			m_invInertiaModel.ey.Identity;

		if m_flags and eLockAxisZ <> 0 then
			m_invInertiaModel.ez.Identity;
	end
	else
	begin
		// Force all dynamic bodies to have some mass
		m_invMass := r32( 1.0 );
		m_invInertiaModel := q3Mat3.Diagonal1( 0.0 );
		m_invInertiaWorld := q3Mat3.Diagonal1( 0.0 );
	end;

	m_localCenter := lc;
	m_worldCenter := q3Mul( m_tx, lc );
end;

procedure q3Body.SynchronizeProxies;
begin
  var broadphase: q3BroadPhase := m_scene.m_contactManager.m_broadphase;
  m_tx.position := m_worldCenter - m_tx.rotation * m_localCenter;

	var aabb: q3AABB;
	var tx: q3Transform := m_tx;

	var box: pq3Box := m_boxes;
	while box <> nil do
	begin
		box.ComputeAABB( tx, aabb );
		broadphase.Update( box.broadPhaseIndex, aabb );
		box := box.next;
	end;
end;

procedure q3Box.SetUserData(data: Pointer);
begin
  userData := data;
end;

function q3Box.GetUserData: Pointer;
begin
  Result := userData;
end;

function q3Box.TestPoint(const tx: q3Transform; const p: q3Vec3): Boolean;
begin
  var world: q3Transform := q3Mul(tx, local);
  var p0: q3Vec3 := q3MulT( world, p);
  for var i := 0 to 2 do
  begin
    var d: r32 := p0.v[ i ];
    var ei: r32 := e.v[ i ];
    if (d > ei) or (d < -ei) then
      Exit(False);
  end;
  Result := True;
end;

function q3Box.Raycast( const tx: q3Transform; raycast: pq3RaycastData): Boolean;
begin
	var world: q3Transform := q3Mul( tx, local );
	var d: q3Vec3 := q3MulT( world.rotation, raycast.dir );
	var p: q3Vec3 := q3MulT( world, raycast.start );
	var epsilon: r32 := r32( 1.0e-8 );
	var tmin: r32 := 0;
	var tmax: r32 := raycast.t;

	var t0: r32;
	var t1: r32;
	var n0: q3Vec3;

	for var i: i32 := 0 to 2 do
	begin
		if Abs( d.v[ i ] ) < epsilon then
		begin
			if ( p.v[ i ] < -e.v[ i ] ) or ( p.v[ i ] > e.v[ i ] ) then
			begin
				Exit(false);
			end;
		end

		else
		begin
			var d0: r32 := r32( 1.0 ) / d.v[ i ];
			var s: r32 := q3Sign( d.v[ i ] );
			var ei: r32 := e.v[ i ] * s;
			var n := q3Vec3.Create( 0, 0, 0 );
			n.v[ i ] := -s;

			t0 := -(ei + p.v[ i ]) * d0;
			t1 := (ei - p.v[ i ]) * d0;

			if t0 > tmin then
			begin
				n0 := n;
				tmin := t0;
			end;

			tmax := Min( tmax, t1 );

			if tmin > tmax then
			begin
				Exit(false);
			end;
		end;
	end;

	raycast.normal := world.rotation * n0;
	raycast.toi := tmin;

	Result := true;
end;

procedure q3Box.ComputeAABB( const tx: q3Transform; var aabb: q3AABB);
begin
	var world: q3Transform := q3Mul( tx, local );

	var v: array[0..7] of q3Vec3;
  v[0].SetXYZ( -e.x, -e.y, -e.z );
  v[1].SetXYZ( -e.x, -e.y,  e.z );
  v[2].SetXYZ( -e.x,  e.y, -e.z );
  v[3].SetXYZ( -e.x,  e.y,  e.z );
  v[4].SetXYZ(  e.x, -e.y, -e.z );
  v[5].SetXYZ(  e.x, -e.y,  e.z );
  v[6].SetXYZ(  e.x,  e.y, -e.z );
  v[7].SetXYZ(  e.x,  e.y,  e.z );

	for var i: i32 := 0 to 7 do
		v[ i ] := q3Mul( world, v[ i ] );

	var min := v[0];
	var max := min;

	for var i: i32 := 1 to 7 do
	begin
		min := min.Min( v[ i ] );
		max := max.Max( v[ i ] );
	end;

	aabb.min := min;
	aabb.max := max;
end;

procedure q3Box.ComputeMass( var md: q3MassData );
begin
	var ex2: r32 := r32( 4.0 ) * e.x * e.x;
	var ey2: r32 := r32( 4.0 ) * e.y * e.y;
	var ez2: r32 := r32( 4.0 ) * e.z * e.z;
	var mass: r32 := r32( 8.0 ) * e.x * e.y * e.z * density;
	var x: r32 := r32( 1.0 / 12.0 ) * mass * (ey2 + ez2);
	var y: r32 := r32( 1.0 / 12.0 ) * mass * (ex2 + ez2);
	var z: r32 := r32( 1.0 / 12.0 ) * mass * (ex2 + ey2);
	var I: q3Mat3 := q3Mat3.Diagonal3( x, y, z );

	I := local.rotation * I * local.rotation.Transpose;
	var identity: q3Mat3;
	identity.Identity;
	I := I + (identity * local.position.Dot( local.position ) - local.position.OuterProduct( local.position )) * mass;

	md.center := local.position;
	md.inertia := I;
	md.mass := mass;
end;

const
  kBoxIndices: array[ 0..35 ] of i32 = (
    1 - 1, 7 - 1, 5 - 1,
    1 - 1, 3 - 1, 7 - 1,
    1 - 1, 4 - 1, 3 - 1,
    1 - 1, 2 - 1, 4 - 1,
    3 - 1, 8 - 1, 7 - 1,
    3 - 1, 4 - 1, 8 - 1,
    5 - 1, 7 - 1, 8 - 1,
    5 - 1, 8 - 1, 6 - 1,
    1 - 1, 5 - 1, 6 - 1,
    1 - 1, 6 - 1, 2 - 1,
    2 - 1, 6 - 1, 8 - 1,
    2 - 1, 8 - 1, 4 - 1
  );

procedure q3Box.Render( const tx: q3Transform; awake: Boolean; render: q3Render; showLinks : Boolean);
begin
	var world: q3Transform := q3Mul( tx, local );
  render.SetAwake(awake);
  Render.DrawCube(world, e);
  if showLinks then
  begin
    var c := body.m_contactList;
    if c <> nil then
    begin
      if body.IsAwake then
        render.SetPenColor(1, 1, 1, 1)
      else
        render.SetPenColor(0.5, 0.5, 0.5, 1);
      render.MoveTo(world.position);
      repeat
        if c.other.IsAwake then
          render.SetPenColor(1, 1, 1, 1)
        else
          render.SetPenColor(0.5, 0.5, 0.5, 1);
        render.LineTo(q3Mul( c.other.m_tx, c.other.m_boxes[0].local ).position);
        c := c.next;
      until c = nil;
    end;
  end;
end;

class operator q3BoxDef.Initialize(out def: q3BoxDef);
begin
  FillChar(def, SizeOf(def), 0);
  def.m_friction := 0.4;
  def.m_restitution := 0.2;
  def.m_density := 1.0;
end;

constructor q3BoxDef.Create(const tx: q3Transform; extents: q3Vec3);
begin
  m_tx := tx;
  m_e := extents * 0.5;
end;

procedure test();
type
  TBoxSlot = TSlot<q3Box>;
  PBoxSlot = ^TBoxSlot;
begin
  var A := TBoxAllocator.Create;

  Assert(A.FFirstPage = nil);
  Assert(A.FFirstFree = nil);

  var B := A.Allocate;

  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstPage = A.FFirstFree);
  Assert(B = @A.FFirstPage.FSlots[0]);
  Assert(PBoxSlot(B).Next = nil);
  Assert(PBoxSlot(B).Page = A.FFirstPage);

  A.Release(B);
  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstPage = A.FFirstFree);
  Assert(B = @A.FFirstPage.FSlots[0]);
  Assert(PBoxSlot(B).Next = @A.FFirstPage.FSlots[1]);

  var Boxes: TArray<pq3Box>;
  SetLength(Boxes, TSlotPage<q3Box>.SLOT_COUNT - 1);
  for var I := 0 to TSlotPage<q3Box>.SLOT_COUNT - 2 do
    Boxes[I] := A.Allocate;

  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstPage = A.FFirstFree);
  for var I := 0 to TSlotPage<q3Box>.SLOT_COUNT - 2 do
    Assert(Boxes[I] = @A.FFirstPage.FSlots[I]);
  Assert(A.FFirstPage.FFreeSlot = @A.FFirstPage.FSlots[TSlotPage<q3Box>.SLOT_COUNT - 1]);

  A.Release(Boxes[5]);
  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstPage.FFreeSlot = @A.FFirstPage.FSlots[5]);
  Assert(A.FFirstPage.FFreeSlot.Next = @A.FFirstPage.FSlots[TSlotPage<q3Box>.SLOT_COUNT - 1]);

  Boxes[5] := A.Allocate;
  Assert(Boxes[5] = @A.FFirstPage.FSlots[5]);
  Assert(A.FFirstPage.FFreeSlot = @A.FFirstPage.FSlots[TSlotPage<q3Box>.SLOT_COUNT - 1]);

  B := A.Allocate;
  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstPage.FFreeSlot = nil);
  Assert(A.FFirstFree = nil);
  Assert(B = @A.FFirstPage.FSlots[TSlotPage<q3Box>.SLOT_COUNT - 1]);

  var B2 := A.Allocate;
  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstPage = A.FFirstFree);
  Assert(A.FFirstFree.FNextPage <> nil);
  Assert(B2 = @A.FFirstPage.FSlots[0]);
  Assert(A.FFirstFree.FFreeSlot = @A.FFirstPage.FSlots[1]);

  A.Release(Boxes[2]);
  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstFree.FNextPage = nil);
  Assert(A.FFirstFree = A.FFirstPage.FNextPage);
  Assert(A.FFirstFree.FFreeSlot = @A.FFirstFree.FSlots[2]);

  Boxes[2] := A.Allocate;
  Assert(A.FFirstPage <> nil);
  Assert(A.FFirstFree <> nil);
  Assert(A.FFirstPage = A.FFirstFree);
  Assert(A.FFirstFree.FNextPage <> nil);
  Assert(B2 = @A.FFirstPage.FSlots[0]);
  Assert(A.FFirstFree.FFreeSlot = @A.FFirstPage.FSlots[1]);

  A.Free;
end;

initialization
{$IFDEF DEBUG}
  test();
{$ENDIF}
end.
