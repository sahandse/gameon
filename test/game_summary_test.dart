import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/src/data/models/game_summary.dart';

void main() {
  test('detects free games from sale price', () {
    const game = GameSummary(id: '1', title: 'Game', normalPrice: 19.99, salePrice: 0);
    expect(game.isFree, isTrue);
  });

  test('detects discounted games', () {
    const game = GameSummary(id: '2', title: 'Game', normalPrice: 59.99, salePrice: 29.99);
    expect(game.isDiscounted, isTrue);
  });

  test('does not mark full price game as discounted', () {
    const game = GameSummary(id: '3', title: 'Game', normalPrice: 59.99, salePrice: 59.99);
    expect(game.isDiscounted, isFalse);
  });
}
