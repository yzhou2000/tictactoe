import 'package:rxdart/rxdart.dart';
import 'package:tic_tac/services/provider.dart';
import 'package:tic_tac/services/sound.dart';

final soundService = locator<SoundService>();

enum BoardState { Done, Play }
enum GameMode { Solo, Multi }

class Move {
  int score;
  int col;
  int row;

  Move({this.score = 0, this.row, this.col});
}


class BoardService {
  BehaviorSubject<List<List<String>>> _board$;
  BehaviorSubject<List<List<String>>> get board$ => _board$;

  BehaviorSubject<String> _player$;
  BehaviorSubject<String> get player$ => _player$;

  BehaviorSubject<MapEntry<BoardState, String>> _boardState$;
  BehaviorSubject<MapEntry<BoardState, String>> get boardState$ => _boardState$;

  BehaviorSubject<GameMode> _gameMode$;
  BehaviorSubject<GameMode> get gameMode$ => _gameMode$;

  BehaviorSubject<MapEntry<int, int>> _score$;
  BehaviorSubject<MapEntry<int, int>> get score$ => _score$;

  String _start;

  BoardService() {
    _initStreams();
  }

  void newMove(int i, int j) {
    String player = _player$.value;
    List<List<String>> currentBoard = _board$.value;

    currentBoard[i][j] = player;
    _playMoveSound(player);
    _board$.add(currentBoard);
    switchPlayer(player);

    bool isWinner = ( _checkWinner(_board$.value) == 'X' || _checkWinner(_board$.value) == 'O' );

    if (isWinner) {
      _updateScore(player);
      _boardState$.add(MapEntry(BoardState.Done, player));
      return;
    } else if (isBoardFull(currentBoard)) {
      _boardState$.add(MapEntry(BoardState.Done, null));
    } else if (_gameMode$.value == GameMode.Solo) {
      botMove();
    }
  }
  bool isEndState(List<List<String>> board) {
    var temp =  _checkWinner(board);
    if (temp == 'N')
      return false;
    return true;
  }

  int getScore(List<List<String>> board, int depth) {
    String res = _checkWinner(board);
    //print(board); print(res);
    if (res == 'X')
      return 10 - depth ;
    else if (res == 'O')
      return -10 + depth;
    return 0; //tie
  }


   maximise(List<List<String>> board, int depth ) {
     if ( isEndState(board) ) {
       return Move(score: getScore(board, depth), row: -1, col: -1);
     }
     Move max = new Move(score: -1000, row: -1, col: -1);

       for (int i = 0; i < 3; i++) {
         for (int j = 0; j < 3; j++) {
           // Is the spot available?
           if (board[i][j] == ' ') {
             board[i][j] = 'X';
             Move curr = minimise(board, depth + 1);
             if (depth ==0 ) {
               print('$i, $j at depth $depth:') ; print(curr.score  );
             }

             if (curr.score > max.score) {
               max.score = curr.score;
               max.row = i;
               max.col = j;
             }
             board[i][j] = ' ';
           }
         }
       }
       return max;
   }

   minimise(List<List<String>> board, int depth ) {
     if (isEndState(board) ) {
       return Move(score: getScore(board, depth), row: -1, col: -1);
     }

     Move min = new Move(score: 1000, row: -1, col:-1);
     //if (depth == 0 ) print(board);

    // print(board);

      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          // Is the spot available?
          if (board[i][j] == ' ') {

            board[i][j] = 'O';

            Move curr = maximise(board, depth + 1);
              if (depth ==0 ) {
                print('$i, $j at depth $depth:') ; print(curr.score  );
              }

            if (curr.score < min.score) {
              min.score = curr.score;
              min.row = i;
              min.col = j;
            }
            board[i][j] = ' ';
          }
        }
      }
     return min;
  }

  botMove() {
    String player = _player$.value;
    List<List<String>> currentBoard = _board$.value;

    Move best;

    //maximise player X and minimise player O

    if (player == 'X' ) {
      best = maximise(currentBoard, 0);
    }
    else {
      best = minimise(currentBoard, 0);
    }


    currentBoard[best.row][best.col] = player;
    _board$.add(currentBoard);
    switchPlayer(player);

    bool isWinner = ( _checkWinner(_board$.value) == 'X' || _checkWinner(_board$.value) == 'O') ;

    if (isWinner) {
      _updateScore(player);
      _boardState$.add(MapEntry(BoardState.Done, player));
      return;
    } else if (isBoardFull(currentBoard)) {
      _boardState$.add(MapEntry(BoardState.Done, null));
    }
  }

  _updateScore(String winner) {
    if (winner == "O") {
      _score$.add(MapEntry(_score$.value.key, _score$.value.value + 1));
    } else if (winner == "X") {
      _score$.add(MapEntry(_score$.value.key + 1, _score$.value.value));
    }
  }

  _playMoveSound(player) {
    if (player == "X") {
      soundService.playSound('x');
    } else {
      soundService.playSound('o');
    }
  }

  equals3(a, b, c) {
    return a == b && b == c && a != ' ';
  }

  String _checkWinner(List<List<String>> board) {
    String winner;
    // Horizontal
    for (int i = 0; i < 3; i++) {
      if (equals3(board[i][0], board[i][1], board[i][2])) {
        winner = board[i][0];
        return winner;
      }
    }
    // Vertical
    for (int i = 0; i < 3; i++) {
      if (equals3(board[0][i], board[1][i], board[2][i])) {
        winner = board[0][i];
        return winner;
      }
    }
    // Diagonal
    if (equals3(board[0][0], board[1][1], board[2][2])) {
      winner = board[0][0];
      return winner;
    }
    if (equals3(board[2][0], board[1][1], board[0][2])) {
      winner = board[2][0];
      return winner;
    }
    for(int i=0; i<3; i++) {
      for(int j=0; j<3; j++ ) {
        if(board[i][j] == ' ') return 'N';
      }
    }
    return 'T';
  }

  void setStart(String e) {
    _start = e;
  }

  void switchPlayer(String player) {
    if (player == 'X') {
      _player$.add('O');
    } else {
      _player$.add('X');
    }
  }

  bool isBoardFull(List<List<String>> currentBoard) {

    List<List<String>> board = currentBoard;
    int count = 0;
    for (var i = 0; i < board.length; i++) {
      for (var j = 0; j < board[i].length; j++) {
        if (board[i][j] == ' ') count = count + 1;
      }
    }
    if (count == 0) return true;

    return false;
  }

  void resetBoard() {
    _board$.add([
      [' ', ' ', ' '],
      [' ', ' ', ' '],
      [' ', ' ', ' ']
    ]);
    _player$.add(_start);
    _boardState$.add(MapEntry(BoardState.Play, ""));
    if (_player$.value == "O") {
      _player$.add("X");
    }
  }

  void newGame() {
    resetBoard();
    _score$.add(MapEntry(0, 0));
  }

  void _initStreams() {
    _board$ = BehaviorSubject<List<List<String>>>.seeded([
      [' ', ' ', ' '],
      [' ', ' ', ' '],
      [' ', ' ', ' ']
    ]);
    _player$ = BehaviorSubject<String>.seeded("X");
    _boardState$ = BehaviorSubject<MapEntry<BoardState, String>>.seeded(
      MapEntry(BoardState.Play, ""),
    );
    _gameMode$ = BehaviorSubject<GameMode>.seeded(GameMode.Solo);
    _score$ = BehaviorSubject<MapEntry<int, int>>.seeded(MapEntry(0, 0));
    _start = 'X';
  }
}
