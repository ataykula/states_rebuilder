import 'package:flutter/material.dart';
import '../states_rebuilder.dart';
import 'reactive_model.dart';
import 'state_builder.dart';

///a combination of [StateBuilder] widget and [ReactiveModel.whenConnectionState] method.
///It Exhaustively switch over all the possible statuses of [ReactiveModel.connectionState]
class WhenRebuilder<T> extends StatelessWidget {
  ///Widget to display when the widget is first rendered and before executing any method.
  ///
  ///It has the third priority after [onWaiting] and [onError]. That is, if none of the observed [ReactiveModel]s
  ///is on the waiting nor on the error state, and if at least one of them is in the idle state this callback will
  ///be invoked.
  final Widget Function() onIdle;

  ///Widget to display when the at least on of the observed [ReactiveModel]s is in the waiting state.
  ///
  ///It has the first priority.That is, if at least one of the observed [ReactiveModel]s is in the waiting state
  /// this callback will be invoked no matter the other states are.
  final Widget Function() onWaiting;

  ///Widget to display when the at least on of the observed [ReactiveModel]s has an error.
  ///
  ///It has the second priority after [onWaiting]. That is none of the observed model is in the waiting state,
  ///and if at least one of the observed [ReactiveModel]s has error this callback will be invoked.
  final Widget Function(dynamic error) onError;

  ///Widget to display if all the observed [ReactiveModel]s has data.
  ///
  ///It has the last priority. That is if all the observed [ReactiveModel]s are not in the waiting state,
  ///have no error, and are not in the idle state, this callback will be invoked.
  final Widget Function(T data) onData;

  ///List of observable classes to which you want this [WhenRebuilder] to subscribe.
  ///```dart
  ///WhenRebuilder(
  ///  models:[myModel1, myModel2, myModel3],
  ///  onIdle: ()=> ...
  ///  onWaiting: ()=> ...
  ///  onError: (error)=> ...
  ///  onData: (data)=> ...
  ///)
  ///```
  ///
  ///For the sake of performance consider using [observe] or [observeMany] instead.
  final List<ReactiveModel> models;

  ///an observable class to which you want [WhenRebuilder] to subscribe.
  ///```dart
  ///WhenRebuilder(
  ///  observe:()=> myModel1,
  ///  onIdle: ()=> ...
  ///  onWaiting: ()=> ...
  ///  onError: (error)=> ...
  ///  onData: (data)=> ...
  ///)
  ///```
  final ReactiveModel<T> Function() observe;

  ///List of observable classes to which you want this [WhenRebuilder] to subscribe.
  ///```dart
  ///WhenRebuilder(
  ///  observeMany:[()=> myModel1,()=> myModel2,()=> myModel3],
  ///  onIdle: ()=> ...
  ///  onWaiting: ()=> ...
  ///  onError: (error)=> ...
  ///  onData: (data)=> ...
  ///)
  ///```
  final List<ReactiveModel Function()> observeMany;

  ///A tag or list of tags you want this [WhenRebuilder] to register with.
  ///
  ///Whenever any of the observable model to which this [WhenRebuilder] is subscribed emits
  ///a notifications with a list of filter tags, this [WhenRebuilder] will rebuild if the
  ///the filter tags list contains at least on of those tags.
  ///
  ///It can be String (for small projects) or enum member (enums are preferred for big projects).
  ///
  ///Each [WhenRebuilder] has a default tag which is its [BuildContext]
  final dynamic tag;

  ///ReactiveModel key used to control this widget from outside its [builder] method.
  final RMKey rmKey;

  ///```dart
  ///WhenRebuilder(
  ///  initState:(BuildContext context, ReactiveModel model)=> myModel.init([context,model]),
  ///  observe:()=> myModel1,
  ///  onIdle: ()=> ...
  ///  onWaiting: ()=> ...
  ///  onError: (error)=> ...
  ///  onData: (data)=> ...
  ///)
  ///```
  ///Called when this object is inserted into the tree.
  final void Function(BuildContext, ReactiveModel<T>) initState;

  ///```dart
  ///StateBuilder(
  ///  dispose:(BuildContext context, ReactiveModel model) {
  ///     myModel.dispose([context, model]);
  ///   },
  ///  observe:()=> myModel1,
  ///  onIdle: ()=> ...
  ///  onWaiting: ()=> ...
  ///  onError: (error)=> ...
  ///  onData: (data)=> ...
  ///)
  ///```
  ///Called when this object is removed from the tree permanently.
  final void Function(BuildContext, ReactiveModel<T>) dispose;

  ///Called whenever this widget is notified.
  final dynamic Function(BuildContext context, ReactiveModel<T> model)
      onSetState;

  const WhenRebuilder({
    Key key,
    @required this.onIdle,
    @required this.onWaiting,
    @required this.onError,
    @required this.onData,
    this.models,
    this.observe,
    this.observeMany,
    this.tag,
    this.rmKey,
    this.initState,
    this.dispose,
    this.onSetState,
  })  : assert(onWaiting != null),
        assert(onError != null),
        assert(onData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<T>(
      models: models,
      observe: observe,
      observeMany: observeMany,
      tag: tag,
      rmKey: rmKey,
      initState: initState,
      dispose: dispose,
      onSetState: onSetState,
      builder: (context, modelRM) {
        bool isIdle = false;
        bool isWaiting = false;
        bool hasError = false;
        dynamic error;
        final _models =
            (context.widget as StateBuilder).activeRM.cast<ReactiveModel>();

        _models.first.whenConnectionState<bool>(
          onIdle: () => isIdle = true,
          onWaiting: () => isWaiting = true,
          onError: (err) {
            error = err;
            return hasError = true;
          },
          onData: (data) => true,
        );

        for (var i = 1; i < _models.length; i++) {
          _models[i].whenConnectionState(
            onIdle: () => isIdle = true,
            onWaiting: () => isWaiting = true,
            onError: (err) {
              error = err;
              return hasError = true;
            },
            onData: (data) => true,
          );
        }

        if (isWaiting) {
          return onWaiting();
        }
        if (hasError) {
          return onError(error);
        }

        if (isIdle) {
          return onIdle();
        }

        return onData(modelRM?.state);
      },
    );
  }
}
