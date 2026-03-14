import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogo da Cobrinha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SnakeGamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum Direction { up, down, left, right }

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  static const int rowCount = 20;
  static const int columnCount = 20;
  static const Duration tick = Duration(milliseconds: 220);

  final Random _random = Random();
  final List<Point<int>> _snake = [
    const Point<int>(10, 10),
    const Point<int>(10, 11),
    const Point<int>(10, 12),
  ];

  late Point<int> _food;
  Direction _direction = Direction.up;
  Timer? _timer;
  bool _running = false;
  bool _gameOver = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _food = _spawnFood();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (_running) return;
    setState(() {
      _running = true;
      _gameOver = false;
    });

    _timer = Timer.periodic(tick, (_) => _updateGame());
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _snake
        ..clear()
        ..addAll(const [
          Point<int>(10, 10),
          Point<int>(10, 11),
          Point<int>(10, 12),
        ]);
      _direction = Direction.up;
      _food = _spawnFood();
      _score = 0;
      _running = false;
      _gameOver = false;
    });
  }

  void _changeDirection(Direction newDirection) {
    if ((_direction == Direction.up && newDirection == Direction.down) ||
        (_direction == Direction.down && newDirection == Direction.up) ||
        (_direction == Direction.left && newDirection == Direction.right) ||
        (_direction == Direction.right && newDirection == Direction.left)) {
      return;
    }

    setState(() {
      _direction = newDirection;
    });
  }

  void _updateGame() {
    if (!_running) return;

    final head = _snake.first;
    Point<int> newHead;

    switch (_direction) {
      case Direction.up:
        newHead = Point<int>(head.x, head.y - 1);
      case Direction.down:
        newHead = Point<int>(head.x, head.y + 1);
      case Direction.left:
        newHead = Point<int>(head.x - 1, head.y);
      case Direction.right:
        newHead = Point<int>(head.x + 1, head.y);
    }

    final hitWall =
        newHead.x < 0 ||
        newHead.x >= columnCount ||
        newHead.y < 0 ||
        newHead.y >= rowCount;
    final hitSelf = _snake.contains(newHead);

    if (hitWall || hitSelf) {
      _timer?.cancel();
      setState(() {
        _running = false;
        _gameOver = true;
      });
      return;
    }

    setState(() {
      _snake.insert(0, newHead);

      if (newHead == _food) {
        _score += 10;
        _food = _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  Point<int> _spawnFood() {
    Point<int> candidate;
    do {
      candidate = Point<int>(_random.nextInt(columnCount), _random.nextInt(rowCount));
    } while (_snake.contains(candidate));
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jogo da Cobrinha'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pontuação: $_score', style: const TextStyle(fontSize: 18)),
                  FilledButton(
                    onPressed: _running ? null : _startGame,
                    child: const Text('Iniciar'),
                  ),
                  OutlinedButton(
                    onPressed: _restartGame,
                    child: const Text('Reiniciar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: columnCount / rowCount,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black12,
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rowCount * columnCount,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                    ),
                    itemBuilder: (context, index) {
                      final x = index % columnCount;
                      final y = index ~/ columnCount;
                      final position = Point<int>(x, y);
                      final isHead = _snake.first == position;
                      final isSnake = _snake.contains(position);
                      final isFood = _food == position;

                      Color color = Colors.white;
                      if (isFood) {
                        color = Colors.red;
                      } else if (isHead) {
                        color = Colors.green.shade900;
                      } else if (isSnake) {
                        color = Colors.green;
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_gameOver)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Fim de jogo! Toque em Reiniciar para jogar novamente.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DirectionPad(onDirectionPressed: _changeDirection),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.onDirectionPressed});

  final ValueChanged<Direction> onDirectionPressed;

  @override
  Widget build(BuildContext context) {
    Widget control(IconData icon, Direction direction) {
      return IconButton.filled(
        onPressed: () => onDirectionPressed(direction),
        icon: Icon(icon),
        iconSize: 28,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        control(Icons.keyboard_arrow_up, Direction.up),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            control(Icons.keyboard_arrow_left, Direction.left),
            const SizedBox(width: 30),
            control(Icons.keyboard_arrow_right, Direction.right),
          ],
        ),
        control(Icons.keyboard_arrow_down, Direction.down),
      ],
    );
  }
}
