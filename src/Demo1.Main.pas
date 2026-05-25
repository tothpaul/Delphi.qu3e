unit Demo1.Main;

interface

uses
  Winapi.OpenGL, Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  RandyGaul.qu3e, Execute.GLPanel, Vcl.AppEvnts;

const
  FACE_COUNT = 6;  // Cube
  EDGE_COUNT = 12;
  VERTEX_COUNT = 8;
  VERTEX_PER_FACE = 4;
  TRIANGLES_PER_FACE = 2;
  VERTICES_PER_TRIANGLE = 3;
  CUBE_SIZE = 2;

type
  TPoint3D = record
    x, y, z: Single;
    constructor Create(ax, ay, az: Single);
  end;

  TTexCoords = record
    u, v: Single;
  end;

  TVertex3D = record
    Position : TPoint3D;
    Normal   : TPoint3D;
//    TexCoords: TTexCoords;
  end;

  TGLCube = class
    Vertices: array[0..(FACE_COUNT * VERTEX_PER_FACE) - 1] of TVertex3D;
    Indices : array[0..(FACE_COUNT * TRIANGLES_PER_FACE * VERTICES_PER_TRIANGLE) - 1] of Integer;
    constructor Create;
    procedure Render;
  end;

  TDemo = class
    procedure Init; virtual; abstract;
    procedure Render(render: q3Render); virtual;
    procedure Update; virtual;
    procedure Shutdown; virtual;
  end;

  TForm1 = class(TForm)
    Panel1: TPanel;
    btTest: TButton;
    GLPanel: TGLPanel;
    ApplicationEvents1: TApplicationEvents;
    btRayCast: TButton;
    Label1: TLabel;
    btDropBoxes: TButton;
    btBoxStack: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure btTestClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Déclarations privées }
    demos: array[0..3] of TDemo;
    start, stop: Int64;
    currentDemo: Integer;
    accumulator: f32;
    cube: TGLCube;
    procedure UpdateScene(time: f32);
    procedure GLSetup(Sender: TObject);
    procedure GLPaint(Sender: TObject);
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  TRenderer = class(q3Render)
  private
    x_,  y_, z_: f32;
    sx_, sy_, sz_: f32;
    nx_, ny_, nz_: f32;
    awake_: Boolean;
  public
    procedure SetPenColor(r, g, b: f32; a: f32 = 1.0); override;
    procedure SetPenPosition(x, y, z: f32); override;
    procedure SetScale(sx, sy, sz: f32); override;
    procedure Line(x, y, z: f32); override;
    procedure DrawCube(const tx: q3Transform; const e: q3Vec3); override;
    procedure Point; override;
    procedure SetAwake(awake: Boolean); override;
  end;

constructor TPoint3D.Create(ax, ay, az: Single);
begin
  x := ax;
  y := ay;
  z := az;
end;

constructor TGLCube.Create;
var
  F, P, I, J, K: Integer;
  S: array[0..1] of Single;
  D, Q: Single;
begin
  F := 0;
  P := 0;
  for I := 1 to FACE_COUNT do
  begin
    Indices[F] := P;
    Inc(F);
    Indices[F] := P + 2;
    Inc(F);
    Indices[F] := P + 1;
    Inc(F);
    Indices[F] := P + 1;
    Inc(F);
    Indices[F] := P + 2;
    Inc(F);
    Indices[F] := P + 3;
    Inc(F);
    Inc(P, 4);
  end;

  for I := 0 to 1 do
  begin
    S[I]  := (I - 0.5) * CUBE_SIZE;
  end;

  P := 0;
  D := +1;
  for K := 0 to 1 do
  begin
    Q := D * CUBE_SIZE / 2;
  // Front / Back
    for J := 0 to 1 do
      for I := 0 to 1 do
      begin
        Vertices[P].Position.X := D * S[I];
        Vertices[P].Position.Y := S[J];
        Vertices[P].Position.Z := -Q;
        Vertices[P].Normal.Z := -D;
        Inc(P);
      end;
  // Left / Right
    for J := 0 to 1 do
      for I  := 0 to 1 do
      begin
        Vertices[P].Position.X := +Q;
        Vertices[P].Position.Y := S[J];
        Vertices[P].Position.Z := D * S[I];
        Vertices[P].Normal.X := +D;
        Inc(P);
      end;
  // Top / Bottom
    for J := 0 to 1 do
      for I  := 0 to 1 do
      begin
        Vertices[P].Position.X := -D * S[I];
        Vertices[P].Position.Y := -Q;
        Vertices[P].Position.Z := S[J];
        Vertices[P].Normal.Y := -D;
        Inc(P);
      end;
    D := -1;
  end;
end;

procedure TGLCube.Render;
begin
  glEnable(GL_LIGHTING);
  glVertexPointer(3, GL_FLOAT, SizeOf(TVertex3D), @Vertices[0].Position);
  glNormalPointer(GL_FLOAT, SizeOf(TVertex3D), @Vertices[0].Normal);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientSTate(GL_NORMAL_ARRAY);
  glDrawElements(GL_TRIANGLES, Length(Indices), GL_UNSIGNED_INT, @Indices);
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientSTate(GL_NORMAL_ARRAY);
  glDisable(GL_LIGHTING);
end;

procedure TRenderer.SetPenColor(r: f32; g: f32; b: f32; a: f32 = 1);
begin
  glColor3f(r, g, b);
end;

procedure TRenderer.SetPenPosition(x: f32; y: f32; z: f32);
begin
  x_ := x; y_ := y; z_ := z;
end;

procedure TRenderer.SetScale(sx: f32; sy: f32; sz: f32);
begin
  glPointSize(sx);
  sx_ := sx; sy_ := sy; sz_ := sz;
end;

procedure TRenderer.Line(x: f32; y: f32; z: f32);
begin
  glBegin(GL_LINES);
  glVertex3f(x_, y_, z_);
  glVertex3f(x, y, z);
  SetPenPosition(x, y, z);
  glEnd();
end;

const
  light1: array[0..3] of single = (1.0, 1.0, 1.0, 1.0);
  light2: array[0..3] of single = (0.25, 0.25, 0.25, 0.5);

procedure TRenderer.DrawCube(const tx: q3Transform; const e: q3Vec3);
var
  M: array[0..15] of Single;
begin
//  if awake_ then
//    glLightfv(GL_LIGHT0, GL_AMBIENT, @light1)
//  else
//    glLightfv(GL_LIGHT0, GL_AMBIENT, @light2);

  glPushMatrix;

  M[ 0] := tx.rotation.ex.x * e.x;
  M[ 1] := tx.rotation.ex.y * e.y;
  M[ 2] := tx.rotation.ex.z * e.z;
  M[ 3] := 0;

  M[ 4] := tx.rotation.ey.x * e.x;
  M[ 5] := tx.rotation.ey.y * e.y;
  M[ 6] := tx.rotation.ey.z * e.z;
  M[ 7] := 0;

  M[ 8] := tx.rotation.ez.x * e.x;
  M[ 9] := tx.rotation.ez.y * e.y;
  M[10] := tx.rotation.ez.z * e.z;
  M[11] := 0;

  M[12] := tx.position.x;
  M[13] := tx.position.y;
  M[14] := tx.position.z;
  M[15] := 1;

  glMultMatrixf(@M);
  Form1.cube.Render;
  glPopMatrix;
end;

procedure TRenderer.Point;
begin
  glBegin(GL_POINTS);
  glVertex3f(x_, y_, z_);
  glEnd();
end;

procedure TRenderer.setAwake(awake: Boolean);
begin
  awake_ := awake;
end;

type
  TCamera = record
    position: array[0..2] of single;
    target: array[0..2] of single;
  end;

  TLight = record
    ambient: array[0..3] of single;
    diffuse: array[0..3] of single;
    specular: array[0..3] of single;
  end;

var
  dt: Single = 1/60;
  scene: q3Scene;
  renderer: TRenderer;

  camera: TCamera = (
    position: (0.0, 5.0, 20.0);
    target  : (0.0, 0.0, 0.0);
  );

  light: TLight = (
    ambient  : (1.0, 1.0, 1.0, 0.5);
    diffuse  : (0.5, 0.4, 0.7, 1.0);
    specular : (1.0, 1.0, 1.0, 1.0);
  );

procedure TDemo.Render(render: q3Render);
begin
  // do nothing
end;

procedure TDemo.Update;
begin
  // do nothing
end;

procedure TDemo.Shutdown;
begin
  scene.RemoveAllBodies;
end;

type
  TDropBoxes = class(TDemo)
  private
    acc: Single;
  public
    procedure Init; override;
    procedure Update; override;
  end;

procedure TDropBoxes.Init;
begin
  acc := 0;

  // Create the floor
	var bodyDef:	q3BodyDef;
  var body: pq3Body := scene.CreateBody( bodyDef );

  var boxDef: q3BoxDef;
  boxDef.restitution := 0;
  var tx: q3Transform;
  tx.Identity;
  boxDef.Create( tx, q3Vec3.Create( 50.0, 1.0, 50.0 ) );
  body.AddBox( boxDef );
end;

procedure TDropBoxes.Update;
begin
		acc := acc + dt;

		if acc > 1.0 then
		begin
			acc := 0;

			var bodyDef: q3BodyDef;
			bodyDef.position.SetXYZ( 0.0, 3.0, 0.0 );
			bodyDef.axis.SetXYZ( q3RandomFloat( -1.0, 1.0 ), q3RandomFloat( -1.0, 1.0 ), q3RandomFloat( -1.0, 1.0 ) );
			bodyDef.angle := PI * q3RandomFloat( -1.0, 1.0 );
			bodyDef.bodyType := eDynamicBody;
			bodyDef.angularVelocity.SetXYZ( q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ) );
			bodyDef.angularVelocity := bodyDef.angularVelocity * q3Sign( q3RandomFloat( -1.0, 1.0 ) );
			bodyDef.linearVelocity.SetXYZ( q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ) );
			bodyDef.linearVelocity := bodyDef.linearVelocity * q3Sign( q3RandomFloat( -1.0, 1.0 ) );
			var body: pq3Body := scene.CreateBody( bodyDef );

			var tx: q3Transform;
			tx.Identity;
			var boxDef: q3BoxDef;
			boxDef.Create( tx, q3Vec3.Create( 1.0, 1.0, 1.0 ) );
			body.AddBox( boxDef );
		end;

end;

type
  TRayCast = record
    data: q3RaycastData;
    tfinal: r32;
    nfinal: q3Vec3;
    impactBody: pq3Body;
    procedure Init;
    function ReportShape(box: pq3Box): Boolean;
  end;

  TRayPush = class(TDemo)
  private
    acc: Single;
    rayCast: TRayCast;
  public
    procedure Init; override;
    procedure Update; override;
    procedure Render(render: q3Render); override;
  end;

procedure TRayCast.Init;
begin
  data.start.SetXYZ(3.0, 5.0, 3.0);
  data.dir := q3Vec3.Create(-1.0, -1.0, -1.0).Normalize;
  data.t := 10000.0;
  tfinal := Q3_R32_MAX;
  data.toi := data.t;
  impactBody := nil;
end;

function TRayCast.ReportShape(box: pq3Box): Boolean;
begin
  if data.toi < tfinal then
  begin
    tfinal := data.toi;
    nfinal := data.normal;
    impactBody := box.Body;
  end;
  data.toi := tfinal;
  Result := True;
end;

procedure TRayPush.Init;
begin
  acc := 0;
  var bodydef: q3BodyDef;
  var body : pq3Body := scene.CreateBody(bodyDef);

  var boxDef: q3BoxDef;
  boxDef.restitution := 0;
  var tx: q3Transform;
  tx.Identity;
  boxDef.Create(tx, q3Vec3.Create(50.0, 1.0, 50.0));
  body.AddBox(boxDef);
end;

procedure TRayPush.Update;
begin
  acc := acc + dt;
  if acc > 1.0 then
  begin
    acc := 0;
    var bodyDef: q3BodyDef;
    bodyDef.position.SetXYZ(0.0, 3.0, 0.0);
    bodyDef.axis.SetXYZ( q3RandomFloat(-1.0, 1.0), q3RandomFloat(-1.0, 1.0), q3RandomFloat(-1.0, 1.0));
    bodyDef.angle := PI * q3RandomFloat(-1.0 , 1.0);
    bodyDef.bodyType := eDynamicBody;
    bodyDef.angularVelocity.SetXYZ( q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ) );
    bodyDef.angularVelocity := bodyDef.angularVelocity * q3Sign( q3RandomFloat( -1.0, 1.0 ) );
    bodyDef.linearVelocity.SetXYZ( q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ), q3RandomFloat( 1.0, 3.0 ) );
    bodyDef.linearVelocity := bodyDef.linearVelocity * q3Sign( q3RandomFloat( -1.0, 1.0 ) );
    var body: pq3Body := scene.CreateBody( bodyDef );

    var tx: q3Transform;
    tx.Identity;
		var boxDef:	q3BoxDef;
    boxDef.Create( tx, q3Vec3.Create( 1.0, 1.0, 1.0 ) );
    body.AddBox( boxDef );
  end;

  rayCast.Init;
  scene.RayCast(rayCast.ReportShape, rayCast.data);

  if rayCast.impactBody <> nil then
  begin
    rayCast.impactBody.SetToAwake;
    rayCast.impactbody.ApplyForceAtWorldPoint(rayCast.data.dir * 2.0, rayCast.data.GetImpactPoint);
  end;
end;

procedure TRayPush.Render(render: q3Render);
begin
  render.SetScale( 1.0, 1.0, 1.0 );
  render.SetPenColor( 0.2, 0.5, 1.0 );
  render.SetPenPosition( rayCast.data.start.x, rayCast.data.start.y, rayCast.data.start.z );
  var impact: q3Vec3 := rayCast.data.GetImpactPoint( );
  render.Line( impact.x, impact.y, impact.z );

  render.SetPenPosition( impact.x, impact.y, impact.z );
  render.SetPenColor( 1.0, 0.5, 0.5 );
  render.SetScale( 10.0, 10.0, 10.0 );
  render.Point( );

  render.SetPenColor( 1.0, 0.5, 0.2 );
  render.SetScale( 1.0, 1.0, 1.0 );
  impact := impact + rayCast.nfinal * 2.0;
  render.Line( impact.x, impact.y, impact.z );
end;

type
  TBoxStack = class(TDemo)
   public
    procedure Init; override;
  end;

procedure TBoxStack.Init;
begin
  // Create the floor
  var bodyDef: q3BodyDef;
  var body: pq3Body := scene.CreateBody( bodyDef );

  var boxDef: q3BoxDef;
  boxDef.restitution := 0;
  var tx: q3Transform;
  tx.Identity;
  boxDef.Create( tx, q3Vec3.Create( 50.0, 1.0, 50.0 ) );
  body.AddBox( boxDef );

  bodyDef.bodyType := eDynamicBody;
  boxDef.Create( tx, q3Vec3.Create( 1.0, 1.0, 1.0 ) );

  for var i: i32 := 0 to 7 do
  begin
    for var j: i32 := 0 to 7 do
    begin
      for var k: i32 := 0 to 9 do
      begin
        bodyDef.position.SetXYZ( -5.0 + 1.0 * j, 1.0 * i + 5.0, -16.0 + 1.0 * k );
        body := scene.CreateBody( bodyDef );
        body.AddBox( boxDef );
      end;
    end;
  end;
end;

type
  TTest = class(TDemo)
  private
    bodyDef: q3BodyDef;
    body   : pq3Body;
    boxDef : q3BoxDef;
    tx: q3Transform;
  public
    procedure Init; override;
  end;

procedure TTest.Init;
begin
  bodyDef.bodyType := eStaticBody;
  bodyDef.position.Identity;
  body := scene.CreateBody(BodyDef);

  boxDef.restitution := 0;
  tx.Identity;
  boxDef.Create(tx, q3Vec3.Create(50.0, 1.0, 50.0));
  body.AddBox(boxDef);

  bodyDef.bodyType := eDynamicBody;
  bodyDef.position.SetXYZ(0, 5.0, 0);
  body := scene.createBody(bodyDef);
  for var i := 0 to 19 do
  begin
    tx.position.SetXYZ(q3RandomFloat(-5.0, +5.0), q3RandomFloat(1.0, +10.0), q3RandomFloat(-5.0, +5.0));
    boxDef.Create(tx, q3Vec3.Create(1.0, 1.0, 1.0));
    body.AddBox(boxDef);
  end;
end;
procedure TForm1.btTestClick(Sender: TObject);
begin
  if currentDemo >= 0 then
    Demos[currentDemo].Shutdown;
  currentDemo := TButton(Sender).Tag;
  stop := GetTickCount;
  Demos[currentDemo].Init;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AllocConsole;
  WriteLn('Hit Ctrl+C to kill the application');
  GLPanel.OnSetup := GLSetup;
  GLPanel.OnPaint := GLPaint;
  scene := q3Scene.Create(dt);
  demos[0] := TDropBoxes.Create;
  demos[1] := TRayPush.Create;
  demos[2] := TBoxStack.Create;
  demos[3] := TTest.Create;
  currentDemo := -1;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  for var i := 0 to High(demos) do
    demos[i].Free;
  renderer.Free;
  scene.Free;
  cube.Free;
end;

procedure TForm1.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  if currentDemo  < 0 then
    Exit;

  start := GetTickCount;
  var time := (start - stop) / 100000;

  UpdateScene(time);
end;

procedure TForm1.UpdateScene(time: f32);
begin
  accumulator := accumulator + time;
  accumulator := q3Clamp01(accumulator);
  while accumulator >= dt do
  begin
    scene.Step;
    demos[currentDemo].Update;
    accumulator := accumulator - dt;
  end;
  Label1.Caption := scene.bodyCount.toString + ' bodies';

  GLPanel.Invalidate;
end;

procedure TForm1.GLSetup(Sender: TObject);
begin
  renderer := TRenderer.Create;
  cube := TGLCube.Create;

  start := GetTickCount;
  stop := start;

  glClearColor( 0.0, 0.0, 0.0, 0.0 );
	glEnable( GL_CULL_FACE );
	glEnable( GL_DEPTH_TEST );
	glCullFace( GL_BACK );
	glFrontFace( GL_CCW );
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
	glEnable( GL_BLEND );

  glLightfv(GL_LIGHT0, GL_AMBIENT, @light.ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, @light.diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, @light.specular);
  glLightfv( GL_LIGHT0, GL_POSITION, @camera.position );
	glEnable( GL_LIGHT0 );
	glColorMaterial( GL_FRONT, GL_AMBIENT_AND_DIFFUSE );

//  glDisable(GL_DEPTH_TEST);
//  glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
end;

procedure TForm1.GLPaint(Sender: TObject);
begin
  glLoadIdentity;
  gluLookAt(
    Camera.position[0], Camera.position[1], Camera.position[2],
    Camera.target[0], Camera.target[1], Camera.target[2],
    0.0, 1.0, 0.0
  );
  if currentDemo >= 0 then
  begin
    scene.Render(renderer);
    demos[currentDemo].Render(renderer);
  end;
end;

end.
