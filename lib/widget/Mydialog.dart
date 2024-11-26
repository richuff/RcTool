import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Mydialog extends Dialog {
  String title;
  String content;
  final Function()? onTab;
  Mydialog({required this.onTab, required this.title,required this.content,super.key});

  @override
  Widget build(BuildContext context){
    return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            height: 300,
            width: 300,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 20,),
                Stack(
                  children: [
                    Align(alignment: Alignment.centerLeft,child: Text(title),),
                    Align(alignment: Alignment.centerRight,child: InkWell(onTap: onTab!(), child:const Icon(Icons.add)))
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10,),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity, child:  Text(content,style: const TextStyle(
                    fontSize: 40
                ),),
                )
              ],
            ),
          ),
        )
    );
  }
}