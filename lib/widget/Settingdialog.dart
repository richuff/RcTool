import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Settingdialog extends Dialog {
  Settingdialog();

  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(5))),
            height: 600,
            width: 380,
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '设置'.tr,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 13, 0),
                          child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.close,
                                size: 24,
                              )),
                        ))
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                        border: Border.all(
                            color: const Color.fromARGB(255, 199, 223, 251),
                            width: 1.0),
                        color: const Color.fromARGB(255, 237, 245, 254)),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 9,
                          child: Icon(
                            size: 30,
                            Icons.info,
                            color: Color.fromARGB(255, 32, 128, 240),
                          ),
                        ),
                        const Positioned(
                          top: 6,
                          left: 34,
                          child: Text(
                            "仅在本地保存",
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          left: 34,
                          child: Container(
                              alignment: Alignment.centerLeft,
                              child: const Text("设置仅在本地保存，清除缓存后将恢复默认设置。")),
                        )
                      ],
                    )),
                Radio(value: "value", groupValue: "groupValue", onChanged: (value){

                })
              ],
            ),
          ),
        ));
  }
}
