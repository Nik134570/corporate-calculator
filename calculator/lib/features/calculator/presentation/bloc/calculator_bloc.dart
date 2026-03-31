import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';
import 'package:calculator/features/calculator/data/models/material_model.dart';
import 'package:calculator/features/calculator/data/repositories/calculator_repository.dart';

abstract class CalculatorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
class CalculatorLoadRequested extends CalculatorEvent {}
class CalculatorDeleteRequested extends CalculatorEvent {
  final String id;
  CalculatorDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

abstract class CalculatorState extends Equatable {
  @override
  List<Object?> get props => [];
}
class CalculatorInitial extends CalculatorState {}
class CalculatorLoading extends CalculatorState {}
class CalculatorLoaded extends CalculatorState {
  final List<CalculationModel> calculations;
  final List<MaterialModel> materials;
  CalculatorLoaded({required this.calculations, required this.materials});
  @override
  List<Object?> get props => [calculations, materials];
}
class CalculatorError extends CalculatorState {
  final String message;
  CalculatorError(this.message);
  @override
  List<Object?> get props => [message];
}

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final CalculatorRepository _repository;

  CalculatorBloc(this._repository) : super(CalculatorInitial()) {
    on<CalculatorLoadRequested>(_onLoad);
    on<CalculatorDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(CalculatorLoadRequested event, Emitter<CalculatorState> emit) async {
    emit(CalculatorLoading());
    try {
      final results = await Future.wait([
        _repository.getAll(),
        _repository.getMaterials(),
      ]);
      emit(CalculatorLoaded(
        calculations: results[0] as List<CalculationModel>,
        materials: results[1] as List<MaterialModel>,
      ));
    } catch (e) {
      emit(CalculatorError('Ошибка загрузки'));
    }
  }

  Future<void> _onDelete(CalculatorDeleteRequested event, Emitter<CalculatorState> emit) async {
    try {
      await _repository.delete(event.id);
      add(CalculatorLoadRequested());
    } catch (e) {
      emit(CalculatorError('Ошибка удаления'));
    }
  }
}