class MonsterBot extends UTBot;

var Actor target;
var() Vector TempDest;



event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition); Pawn.SetMovementPhysics();
} //I'm adding an default idle state so the Pawn doesn't try to follow a player that doesn' exist yet.
 

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
        class'NavMeshGoal_Random'.static.FindRandom( NavigationHandle );  // no idea what this does but hopefully someone will?
        
        // Find path
        return NavigationHandle.FindPath();
    }
    
    Begin:
    
    if( FindNavMeshPath())
    {
        FlushPersistentDebugLines();
        NavigationHandle.DrawPathCache(,TRUE); //This handles drawing the blue mesh for Debugging purposes
        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
        {
            DrawDebugLine(Pawn.Location,TempDest,255,0,0,true); //These two lines handle drawing the red line and sphere for debugging purposes
            DrawDebugSphere(TempDest,16,20,255,0,0,true);
            
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
        NavigationHandle.DrawPathCache(,TRUE); //This handles drawing the blue mesh for Debugging purposes
 
        // move to the first node on the path
        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
        {
            DrawDebugLine(Pawn.Location,TempDest,255,0,0,true); //These two lines handle drawing the red line and sphere for debugging purposes
            DrawDebugSphere(TempDest,16,20,255,0,0,true);
 
            MoveTo( TempDest, target );
        }
    }
    else
    {
        //We can't follow, so get the hell out of this state, otherwise we'll enter an infinite loop.
        GotoState('Roam');
    }

    goto 'Begin';
}
 
DefaultProperties
{
}