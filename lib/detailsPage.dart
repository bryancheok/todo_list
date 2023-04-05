
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import 'TodoItem.dart';
import 'localNotificationPop.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.itemID, required this.description, required this.deadline, required this.refreshPage});

  final String itemID;
  final String description;
  final String deadline;
  final Function refreshPage;

  @override
  State<DetailsPage> createState() => _DetailsPage();
}

class _DetailsPage extends State<DetailsPage> {

  List<ToDoItem> toDoitems = [];
  List<String> tempArr = [];
  late Map<String, dynamic> saveItem;
  late String inputDesc = widget.description;
  late String inputDeadl = widget.deadline;
  late String defaultDesc = widget.description;
  late String defaultDeadl = widget.deadline;
  late String savedDesc = widget.description;
  late String savedDeadl = widget.deadline;

  final calendarControl = DateRangePickerController();
  final inputText = TextEditingController();
  bool editStatus = false;

  goBack(arr) {
    Navigator.pop(context, arr);
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
    }
  }

  String dateToString(date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  DateTime stringToDate(str) {
    return DateFormat('dd/MM/yyyy').parse(str);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      inputText.text = widget.description;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          FloatingActionButton(
            backgroundColor: null,
            elevation: 0,
            onPressed: () => {
              SharedPreferences.getInstance().then((prefs) =>
                {
                  getSharedPrefs().then((e) => {
                    setState(() {
                      removeNotification(widget.itemID);
                      toDoitems.removeWhere((v) => v.itemID == widget.itemID);
                      for (var v in toDoitems) { 
                        saveItem = {'itemID':v.itemID,'description':v.description, 'deadline': v.deadline};
                        tempArr.add(jsonEncode(saveItem));
                      }
                      prefs.setStringList("savedArray", tempArr).then((value) => {
                        goBack(toDoitems)
                      });
                    }),
                  }),
                }
              ),
            },
            child: 
              const Icon(Icons.delete),
          )      
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: 
          Column(
            children: [
              Expanded(child: 
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width* 0.06, vertical: MediaQuery.of(context).size.height* 0.05),
                  child:          
                    Column(
                      children: [
                        TextField(
                          controller: inputText,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 100,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          onChanged: (v) {
                            setState(() {
                              inputDesc = v;
                            });
                          },
                          readOnly: ((){
                            if(editStatus){
                              return false;
                            }
                            else {
                              return true;
                            }
                          }()),
                        ),

                        Container(
                          padding: const EdgeInsets.only(top: 20),
                          height: 300,
                          width: double.maxFinite,
                          child: ((){
                            if(editStatus){
                              return SfDateRangePicker(
                                controller: calendarControl,
                                initialSelectedDate: stringToDate(inputDeadl),
                                selectionMode: DateRangePickerSelectionMode.single,
                                onSelectionChanged: (v) {
                                  setState(() {
                                    inputDeadl = dateToString(v.value);
                                  });
                                },
                              );
                            }
                            else {
                              return Text('Deadline: $inputDeadl');
                            }
                          }())                                            
                        ),
                      ],
                    ),
                ),
              ),
            ]
        ),
      ),
      
      floatingActionButton: 
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Visibility(
              visible: editStatus,
              child: 
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      inputDeadl = savedDeadl;
                      inputDesc = savedDesc;
                      inputText.text = savedDesc;
                      editStatus = false;
                    });
                  },
                  backgroundColor: Colors.red[400],
                  child: 
                    const Icon(Icons.close),
                ),
            ),
            
            const SizedBox(
              width: 10,
            ),

            Visibility(
              visible: editStatus,
              child: 
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      inputDeadl = defaultDeadl;
                      inputDesc = defaultDesc;
                      inputText.text = defaultDesc;
                      calendarControl.selectedDate = stringToDate(inputDeadl);
                    });
                  },
                  backgroundColor: Colors.yellow[400],
                  child: 
                    const Icon(Icons.refresh_rounded),
                ),
            ),
            
            const SizedBox(
              width: 10,
            ),

            FloatingActionButton(
              onPressed: () {
                if(editStatus){
                  setState(() {
                    SharedPreferences.getInstance().then((prefs) =>
                      {
                        getSharedPrefs().then((e) => {
                          setState(() {
                            savedDesc = inputDesc;
                            savedDeadl = inputDeadl;
                            int i = toDoitems.indexWhere((v) => v.itemID == widget.itemID);
                            toDoitems[i].description = inputDesc;
                            toDoitems[i].deadline = inputDeadl;
                            for (var v in toDoitems) { 
                              saveItem = {'itemID':v.itemID,'description':v.description, 'deadline': v.deadline};
                              tempArr.add(jsonEncode(saveItem));
                            }
                            prefs.setStringList("savedArray", tempArr).then((value) => {
                              widget.refreshPage(toDoitems),
                              tempArr.clear(),
                              Fluttertoast.showToast(
                                msg: 'Done !',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.greenAccent.withOpacity(0.7),
                                textColor: Colors.white,
                                fontSize: 14.0,
                              ),

                              removeNotification(widget.itemID),
                              showNotification(widget.itemID, "To Do Alert !", inputDesc, stringToDate(inputDeadl)),
                            });
                          }),
                        }),
                      }
                    );
                    
                    editStatus = false;
                  });
                }
                else {
                  setState(() {
                    editStatus = true;
                  });
                }
              },
              backgroundColor: ((){
                if(editStatus){
                  return Colors.green;
                }
                else {
                  return Colors.blue.shade600;
                }
              }()),
              child: 
                Icon(
                  (() {
                    if(editStatus){
                      return Icons.check;
                    }
                    else {
                      return Icons.edit;
                    }
                  } ()),
                ),
            ),
          ],
        )
    );
  }
}
