class MonsterBot extends UTBot;

var Actor target;
var() Vector TempDest;


event stopFollowing()
{
    WorldInfo.Game.Broadcast(self,"Lost Interest");
    GotoState('Roam');
}


event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    Pawn.SetMovementPhysics();
    gotoState('Roam');
}


event SeePlayer (Pawn Seen)
{
    super.SeePlayer(Seen);
    target = Seen;
    gotoState('Follow');
}

auto state Roam
{
    function bool FindNavMeshPath()
    {
        WorldInfo.Game.Broadcast(self,"Roaming");
        // Clear cache and constraints (ignore recycling for the moment)
        NavigationHandle.PathConstraintList = none;
        NavigationHandle.PathGoalList = none;

        class'NavMeshPath_EnforceTwoWayEdges'.static.EnforceTwoWayEdges(NavigationHandle);  // don't want out bot to go anywhere it's not supposed to
        class'NavMeshGoal_Random'.static.FindRandom( NavigationHandle );

        // Find path
        return NavigationHandle.FindPath();
    }

    Begin:

    if( FindNavMeshPath())
    {
        FlushPersistentDebugLines();
        //NavigationHandle.DrawPathCache(,TRUE);//This handles drawing the blue mesh for Debugging purposes. REMOVE TO REMOVE BLUE LINES
        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
        {
           // DrawDebugLine(Pawn.Location,TempDest,255,0,0,true); //These two lines handle drawing the red line and sphere for debugging purposes
           // DrawDebugSphere(TempDest,16,20,255,0,0,true);

            MoveTo(TempDest);
        }
    }
    goto 'Begin';
}

state Follow
{
    ignores SeePlayer;
    function bool FindNavMeshPath()
    {
        WorldInfo.Game.Broadcast(self,"Following");
        // Clear cache and constraints (ignore recycling for the moment)
        NavigationHandle.PathConstraintList = none;
        NavigationHandle.PathGoalList = none;
 
        // Create constraints
        class'NavMeshPath_Toward'.static.TowardGoal( NavigationHandle,target );
        class'NavMeshGoal_At'.static.AtActor( NavigationHandle, target,32 );

        // Find path
        return NavigationHandle.FindPath();
    }
Begin:
    if(!LineOfSightTo(Target))
    {
         gotoState('blindFollow');
    }
    if( NavigationHandle.ActorReachable( target) )
    {
        FlushPersistentDebugLines();

        //Direct move
        MoveToward( target,target );
    }
    else if( FindNavMeshPath() )
    {
        NavigationHandle.SetFinalDestination(target.Location);
        FlushPersistentDebugLines();
       // NavigationHandle.DrawPathCache(,TRUE); //This handles drawing the blue mesh for Debugging purposes

        // move to the first node on the path
        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
        {
            //DrawDebugLine(Pawn.Location,TempDest,255,0,0,true); //These two lines handle drawing the red line and sphere for debugging purposes
           // DrawDebugSphere(TempDest,16,20,255,0,0,true);

            MoveTo( TempDest, target );
        }
    }
    else
    {
        //We can't follow, so get the hell out of this state, otherwise we'll enter an infinite loop.
        GotoState('Roam');
    }
    if (VSize(Pawn.Location - target.Location) <= 70)
    {
       GotoState('Attack'); //Start attacking when close enough to the player.
    }
    else
    {
      goto'Begin';
    }
}

state Attack
{
      ignores seePlayer;
   Begin:
      WorldInfo.Game.Broadcast(self,"Attacking");
      Pawn.ZeroMovementVariables();
      //Sleep(3); //Give the pawn the time to stop.
    WorldInfo.Game.Broadcast(self,Pawn);
    WorldInfo.Game.Broadcast(self,Pawn.Weapon);
    Pawn.BotFire(true);
    Pawn.BotFire(true);
    Pawn.BotFire(false);

    GotoState('Follow');
}
simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
{
    // AI does things from the Pawn
    if (Pawn != None)
    {
        out_Location = Pawn.Location;
        out_Rotation = Rotation; //That's what we've changed
    }
    else
    {
        Super.GetPlayerViewPoint(out_Location, out_Rotation);
    }
}
state blindFollow
{  

    function bool FindNavMeshPath()
    {
        WorldInfo.Game.Broadcast(self,"Blind Following");
        // Clear cache and constraints (ignore recycling for the moment)
        NavigationHandle.PathConstraintList = none;
        NavigationHandle.PathGoalList = none;

        // Create constraints
        class'NavMeshPath_Toward'.static.TowardGoal( NavigationHandle,target );
        class'NavMeshGoal_At'.static.AtActor( NavigationHandle, target,32 );


        // Find path
        return NavigationHandle.FindPath();
    }
 Begin:
        //Sets Timer to move to roam
        setTimer(5, false, 'stopFollowing');
    if( NavigationHandle.ActorReachable( target) )
    {
        FlushPersistentDebugLines();

        //Direct move
        MoveToward( target,target );
    }
    else if( FindNavMeshPath() )
    {
        NavigationHandle.SetFinalDestination(target.Location);
        FlushPersistentDebugLines();
        //NavigationHandle.DrawPathCache(,TRUE); //This handles drawing the blue mesh for Debugging purposes

        // move to the first node on the path
        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
        {
            //DrawDebugLine(Pawn.Location,TempDest,255,0,0,true); //These two lines handle drawing the red line and sphere for debugging purposes
           // DrawDebugSphere(TempDest,16,20,255,0,0,true);

            MoveTo( TempDest, target );
        }
    }
    else
    {
        //We can't follow, so get the hell out of this state, otherwise we'll enter an infinite loop.
        GotoState('Roam');
    }

    if (VSize(Pawn.Location - target.Location) <= 16)
    {
       GotoState('Attack'); //Start attacking when close enough to the player.
    }
    else
    {
      goto 'Begin';
    }

 }





DefaultProperties
{
}