import 'package:flutter/material.dart';


class Mydialog extends Dialog {
  String title;
  String content;
  Mydialog({required this.title,required this.content,super.key});

  @override
  Widget build(BuildContext context){
    return Opacity(opacity: 0.6,child:
    Material(
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
                    Align(alignment: Alignment.center,child: Text(title),),
                    Align(alignment: Alignment.centerRight,child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 0,13, 0),
                      child: InkWell(onTap: (){
                        Navigator.of(context).pop();
                      }, child:const Icon(Icons.close,size: 24,)),
                    ))
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
    ));
  }
}