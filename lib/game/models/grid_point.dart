class GridPoint {
  const GridPoint(this.row, this.column);

  final int row;
  final int column;

  bool isAdjacentTo(GridPoint other) {
    return (row - other.row).abs() + (column - other.column).abs() == 1;
  }

  @override
  bool operator ==(Object other) {
    return other is GridPoint && other.row == row && other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}
