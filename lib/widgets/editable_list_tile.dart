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

class EditableListTile extends StatelessWidget {
  final TextEditingController _textEditingController;

  final IconData icon;

  final VoidCallback onRemove;

  final VoidCallbackWithValue onContentsChanged;
  final VoidCallbackWithValue onContentsSubmitted;

  final VoidCallback? onTap;

  final EditCubit editCubit = EditCubit();

  String get text => _textEditingController.text;

  EditableListTile({
    required this.icon,
    required String initialContents,
    required this.onRemove,
    required this.onContentsChanged,
    required this.onContentsSubmitted,
    super.key,
    this.onTap,
  }) : _textEditingController = TextEditingController(text: initialContents);

  void _onStartEditing() {
    editCubit.declareEditing(originalValue: text);
  }

  void _onFinishEditing() {
    onContentsSubmitted(text);
    editCubit.declareNotEditing();
  }

  void _onCancelEditing() {
    final state = editCubit.state;
    if (state is! EditingState) {
      return;
    }

    _textEditingController.text = state.originalValue;

    editCubit.declareCancelled();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<EditCubit, EditState>(
        bloc: editCubit,
        builder: (context, state) => ListTile(
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap:
                    state is EditingState ? _onCancelEditing : _onStartEditing,
                child: Icon(
                  state is EditingState ? Icons.close : Icons.edit,
                  color: Theme.of(context).listTileTheme.iconColor,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  icon,
                  color: Theme.of(context).listTileTheme.iconColor,
                ),
              ),
            ],
          ),
          title: TextField(
            controller: _textEditingController,
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: onContentsChanged,
            onSubmitted: (value) => _onFinishEditing(),
            style: Theme.of(context).textTheme.labelLarge,
            enabled: editCubit.state is EditingState,
          ),
          tileColor: Theme.of(context).listTileTheme.tileColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
        ),
      );
}
