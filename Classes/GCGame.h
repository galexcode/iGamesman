//
//  GCGame.h
//  GamesmanMobile
//
//  Created by Kevin Jorgensen on 1/29/10.
//  Copyright 2010 GamesCrafters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCOptionMenu.h"

typedef enum { ONLINE_SOLVED, OFFLINE_UNSOLVED } PlayMode;
typedef enum { WIN, LOSE, TIE, DRAW, UNAVAILABLE } GameValue;
typedef enum { HUMAN, COMPUTER_RANDOM, COMPUTER_PERFECT } PlayerType;
typedef enum { PLAYER1, PLAYER2, NONE } Player;

/**
 Superclass of all game objects
 Do not use! This is a superclass only!
 Treat this like an abstract class!
 
 Subclasses should have the current board in their local state
 and update it at appropriate times.
 */
@interface GCGame : NSObject {

}

/// Return the game's name
- (NSString *) gameName;

/// Getter for Player 1's name
- (NSString *) player1Name;
/// Getter for Player 1's name
- (NSString *) player2Name;

/// Setter for the Player 1's name
- (void) setPlayer1Name: (NSString *) p1;
/// Setter for the Player 2's name
- (void) setPlayer2Name: (NSString *) p2;

/// Getter for Player 1 Type
- (PlayerType) player1Type;
/// Getter for Player 2 Type
- (PlayerType) player2Type;

/// Setter for Player 1 Type
- (void) setPlayer1Type: (PlayerType) type;
/// Setter for Player 2 Type
- (void) setPlayer2Type: (PlayerType) type;

/// Return YES for supported mode(s)
- (BOOL) supportsPlayMode: (PlayMode) mode;

/// Return the option menu
- (UIViewController<GCOptionMenu> *) optionMenu;

/// Return the game's view controller
- (UIViewController *) gameViewController;

/// Do anything necessary to get the game started
- (void) startGame;

/// Getter for Predictions
- (BOOL) predictions;
/// Getter for Move Values
- (BOOL) moveValues;

/// Setter for Predictions
/// Must update the view to reflect the new settings
- (void) setPredicitons: (BOOL) pred;
/// Setter for Move Values
/// Must update the view to reflect the new settings
- (void) setMoveValues: (BOOL) move;

/// Return the current board
- (id) getBoard;

/// Return the name of the player whose turn it is
- (Player) getPlayer;

/// Return the value of the current board
- (GameValue) getValue;

/// Return the remoteness of the current board (or -1 if not available)
- (NSInteger) getRemoteness;

/// Return the value of MOVE
- (GameValue) getValueOfMove: (id) move;

/// Return the remoteness of MOVE (or -1 if not available)
- (NSInteger) getRemotenessOfMove: (id) move;

/// Return an array of legal moves using the current board
- (NSArray *) legalMoves;

/// Return YES if THEBOARD is primitive, NO if not
- (BOOL) isPrimitive: (id) theBoard;

/// Ask the user for input
- (void) askUserForInput;

/// End asking for user input
- (void) stopUserInput;

/// Get the current player
- (Player) currentPlayer;

/// Get the move the user chose (only called after the GameController receives a notification)
- (id) getHumanMove;

/// Perform MOVE and update the view accordingly (MOVE is assumed to be legal)
- (void) doMove: (id) move;

@end
