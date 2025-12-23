class RemoteButton {
  final int? id;
  final int remoteId;
  final String label;
  final int color; // Store as int (0xAARRGGBB)
  final String iconCode; // Store icon code point or name
  final String? irCode; // The raw IR code string (e.g., "NEC,0x20DF10EF,32")

  RemoteButton({
    this.id,
    required this.remoteId,
    required this.label,
    required this.color,
    required this.iconCode,
    this.irCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remote_id': remoteId,
      'label': label,
      'color': color,
      'icon_code': iconCode,
      'ir_code': irCode,
    };
  }

  factory RemoteButton.fromMap(Map<String, dynamic> map) {
    return RemoteButton(
      id: map['id'],
      remoteId: map['remote_id'],
      label: map['label'],
      color: map['color'],
      iconCode: map['icon_code'],
      irCode: map['ir_code'],
    );
  }
}
