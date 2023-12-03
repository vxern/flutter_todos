import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class EditState {
  const EditState();
}

class NotEditingState extends EditState {
  const NotEditingState();
}

class EditingState extends EditState with EquatableMixin {
  final String originalValue;

  const EditingState({required this.originalValue});

  @override
  List<Object> get props => [originalValue];
}

class CancelledEditingState extends EditState {
  const CancelledEditingState();
}

class EditCubit extends Cubit<EditState> {
  EditCubit() : super(const NotEditingState());

  void declareEditing({required String originalValue}) =>
      emit(EditingState(originalValue: originalValue));

  void declareNotEditing() => emit(const NotEditingState());

  void declareCancelled() => emit(const CancelledEditingState());
}

typedef VoidCallbackWithValue = void Function(String contents);

class EditableListTile extends StatefulWidget {
  final TextEditingController _textEditingController;

  final IconData icon;

  final VoidCallback onRemove;

  final VoidCallbackWithValue onContentsChanged;
  final VoidCallbackWithValue onContentsSubmitted;

  final VoidCallback? onTap;

  EditableListTile({
    required this.icon,
    required String initialContents,
    required this.onRemove,
    required this.onContentsChanged,
    required this.onContentsSubmitted,
    super.key,
    this.onTap,
  }) : _textEditingController = TextEditingController(text: initialContents);

  @override
  State<EditableListTile> createState() => _EditableListTileState();
}

class _EditableListTileState extends State<EditableListTile> {
  final EditCubit editCubit = EditCubit();

  String get text => widget._textEditingController.text;

  void _onStartEditing() {
    editCubit.declareEditing(originalValue: text);
  }

  void _onFinishEditing() {
    widget.onContentsSubmitted(text);
    editCubit.declareNotEditing();
  }

  void _onCancelEditing() {
    final state = editCubit.state;
    if (state is! EditingState) {
      return;
    }

    widget._textEditingController.text = state.originalValue;

    editCubit.declareCancelled();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<EditCubit, EditState>(
        bloc: editCubit,
        builder: (context, state) => TextFieldTapRegion(
          child: ListTile(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: state is EditingState
                      ? _onCancelEditing
                      : _onStartEditing,
                  child: Icon(state is EditingState ? Icons.close : Icons.edit),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(widget.icon),
                ),
              ],
            ),
            title: TextField(
              controller: widget._textEditingController,
              onChanged: widget.onContentsChanged,
              onTapOutside: (value) => _onFinishEditing(),
              onSubmitted: (value) => _onFinishEditing(),
              style: TextStyle(
                color: Theme.of(context).listTileTheme.textColor,
                decoration: state is EditingState
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationThickness: .4,
              ),
              enabled: editCubit.state is EditingState,
            ),
            onTap: widget.onTap,
          ),
        ),
      );
}
