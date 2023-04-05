
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'detailsPage.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'TodoItem.dart';
import 'localNotificationPop.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        primarySwatch: Colors.orange,
      ),
      home: const MyHomePage(title: 'To-Do List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String _inputStr = '';
  List<ToDoItem> toDoitems = [];
  List<String> selectedIDs = [];

  bool deletePopUp = false;
  bool deleteMode = false;
  String newDeadl = DateFormat('dd/MM/yyyy').format(DateTime.now());

  final input1 = TextEditingController();
  
  refreshDetail(arr) {
    setState(() {
      toDoitems = arr;
      sortTodoItems();
    });
  }

  Future<void> getSharedPrefs() async {
    toDoitems.clear();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getStringList("savedArray") != null) {
      prefs.getStringList("savedArray")?.forEach((v) => {
        setState(() {
          Map<String,dynamic> itemMap = jsonDecode(v) as Map<String, dynamic>;
          final anItem = ToDoItem(itemMap['itemID']??0,itemMap['description']??0,itemMap['deadline']??0);
          toDoitems.add(anItem);
        })
      });
      sortTodoItems();
    }
  }

  Future<void> _toDetails(BuildContext context, id, desc, deadl) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailsPage(itemID: id, description: desc, deadline: deadl, refreshPage: refreshDetail,)),
    );
    if (!mounted) return;
    setState(() {
      toDoitems = result;
    });
  }

  Future<void> _showDeleteAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete item'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Delete ${selectedIDs.length.toString()} selected items ?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                SharedPreferences.getInstance().then((prefSave) async{
                  setState(() {
                    for (var sid in selectedIDs) {
                      toDoitems.removeWhere((v) => v.itemID == sid);
                      removeNotification(sid);
                    }
                    List<String> tempArr = [];
                    for (var v in toDoitems) { 
                      Map<String, dynamic>  saveItem = {'itemID':v.itemID,'description':v.description, 'deadline': v.deadline};
                      tempArr.add(jsonEncode(saveItem));
                    }
                    prefSave.setStringList("savedArray", tempArr).then((value) => {
                      Navigator.of(context).pop(),
                      Fluttertoast.showToast(
                        msg: 'Item Deleted',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.deepOrange.withOpacity(0.7),
                        textColor: Colors.white,
                        fontSize: 14.0,
                      ),
                    });
                    deleteMode = false;
                  });
                });
              },
            ),
          ],
        );
      },
    );
  }
  
  showCreatenewPop() {
    setState(() {
      newDeadl = dateToString(DateTime.now());
      _inputStr = '';
    });

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: 
        (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                scrollable: true,
                title: const Text('Create new item'),
                content:
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: input1,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 100,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        onChanged: (value) => setState(() {
                          if(value.isEmpty) {
                            _inputStr = '';
                          }
                          else {
                            _inputStr = value;
                          }
                        }),
                        textAlign: TextAlign.start,
                        decoration: const InputDecoration(
                          hintText: '',
                        ),
                      ),

                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          Text(newDeadl),
                        ],
                      ),
                      
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        height: 300,
                        width: double.maxFinite,
                        child: SfDateRangePicker(
                          initialSelectedDate: DateTime.now(),
                          selectionMode: DateRangePickerSelectionMode.single,
                          onSelectionChanged: (v) {
                            setState(() {
                              newDeadl = dateToString(v.value);
                            });
                          },
                        ),
                      )
                    ],
                  ),

                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      input1.clear();
                      setState(() {
                        _inputStr = '';
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Confirm'),
                    onPressed: () async {
                      input1.clear();
                      final prefs = await SharedPreferences.getInstance();
                      final uniqueID = UniqueKey().hashCode.toString();
                      Map<String, dynamic> saveItem = {'itemID':uniqueID,'description':_inputStr, 'deadline': newDeadl};
                      final newItem = ToDoItem(uniqueID, _inputStr, newDeadl);      
                                          
                      setState(() {
                        _inputStr = '';
                        toDoitems.add(newItem);
                        List<String> encodedList = [];
                        for (var v in toDoitems) { 
                          saveItem = {'itemID':v.itemID,'description':v.description, 'deadline': v.deadline};
                          encodedList.add(jsonEncode(saveItem));
                        }
                        prefs.setStringList('savedArray', encodedList).then((r) => {
                          sortTodoItems(),
                          Navigator.of(context).pop(),
                        });

                        showNotification(newItem.itemID, "To Do Alert !", getShortStr(newItem.description), stringToDate(newItem.deadline));
                      });
                    },
                  ),
                ],
              );
            }
          );
        },
      );
  }

  sortTodoItems() {
    setState(() {
      toDoitems.sort((a, b) => stringToDate(a.deadline).compareTo(stringToDate(b.deadline)));
    });
  }

  String dateToString(date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  DateTime stringToDate(str) {
    return DateFormat('dd/MM/yyyy').parse(str);
  }

  String getShortStr(str) {
    if(str.toString().length > 20){
      return '${str.toString().substring(0,21)}...';
    }
    else {
      return str;
    }
  }

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          FloatingActionButton(
            backgroundColor: null,
            elevation: 0,
            onPressed: () async {
              if(deleteMode){
                _showDeleteAlert();
              }
              else {
                showCreatenewPop();
              }
            },
            child: 
              Icon((){
                if(deleteMode){
                  return Icons.delete;
                }
                else {
                  return Icons.add_box_rounded;
                }
              }()),
          )
        ],
      ),
      body: 
        GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child:
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width* 0.03, vertical: MediaQuery.of(context).size.height* 0.02),
              child: 
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[  
                    Visibility(
                      visible: ((){
                        if(toDoitems.isEmpty){
                          return true;
                        }
                        else {
                          return false;
                        }
                      }()),
                      child: 
                        const Text(
                          'No items',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        )
                    ),
                                      
                    ListView.builder (
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: toDoitems.length,
                      itemBuilder: ((context, index) {
                        final id  = toDoitems[index].itemID;
                        final desc = getShortStr(toDoitems[index].description);
                        final deadl = toDoitems[index].deadline;
                        return Card(
                          child: 
                            ListTile(
                              title: Text(
                                getShortStr(desc),
                                maxLines: 5,
                              ),
                              subtitle: Text(deadl),
                              trailing: Icon((){
                                if(selectedIDs.contains(toDoitems[index].itemID)){
                                  return Icons.check_box_rounded;
                                }
                                else {
                                  return Icons.check_box_outline_blank_rounded;
                                }
                              }()),
                              tileColor: ((){
                                int diff = stringToDate(deadl).difference(DateTime.now()).inDays;
                                if(diff < 7){
                                  return Colors.red[200];
                                }
                                else if(diff >= 7 && diff <= 31){
                                  return Colors.yellow[200];
                                }
                                else {
                                  return Colors.green[200];
                                }
                              }()),
                              onTap: () async {
                                if(deleteMode){
                                  if(selectedIDs.contains(toDoitems[index].itemID)){
                                    setState(() {
                                      selectedIDs.remove(toDoitems[index].itemID);
                                      if(selectedIDs.isEmpty){
                                        deleteMode = false;
                                      }
                                    });
                                  }
                                  else {
                                    setState(() {
                                      selectedIDs.add(toDoitems[index].itemID);
                                    });
                                  }
                                }
                                else {
                                  setState(() {
                                    deleteMode = false;
                                  });
                                  FocusScope.of(context).requestFocus(FocusNode());
                                  _toDetails(context,id,toDoitems[index].description,toDoitems[index].deadline);
                                }
                              },
                              onLongPress: () async {
                                setState(() {
                                  deleteMode = true;
                                  selectedIDs = [];
                                  selectedIDs.add(toDoitems[index].itemID);
                                });
                              },
                            ),
                        );
                      }),
                    ),
                  ],     
                ),
            ),            
        ),
    );
  }
}
