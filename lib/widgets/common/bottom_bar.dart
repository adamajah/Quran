// ─────────────────────────────────────────────────────────────────────────────
// Bottom Bar & shared nav widgets  (extracted from home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/tajwid_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BottomBar
// ─────────────────────────────────────────────────────────────────────────────
class BottomBar extends StatelessWidget {
  final bool playing, showTajwid;
  final String reciter, surahName;
  final int pageNum, playVerse;
  final VoidCallback onPlay, onStop;
  final double fontScale;
  final VoidCallback onZoomIn, onZoomOut, onZoomReset;
  final VoidCallback onToggleTajwid;
  final VoidCallback onTajwidLongPress;

  const BottomBar({
    super.key,
    required this.playing, required this.reciter, required this.surahName,
    required this.pageNum, required this.playVerse,
    required this.onPlay, required this.onStop,
    required this.fontScale,
    required this.onZoomIn, required this.onZoomOut, required this.onZoomReset,
    required this.showTajwid, required this.onToggleTajwid,
    required this.onTajwidLongPress,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.pageBg,
      border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.35), width: 1)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0,-2))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(children: [
      PBtn(icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded, active: playing, onTap: onPlay),
      const SizedBox(width: 4),
      PBtn(icon: Icons.stop_rounded, active: false, onTap: onStop),
      const SizedBox(width: 6),
      _Divider(),
      const SizedBox(width: 6),
      PBtn(icon: Icons.remove_rounded, active: false, onTap: onZoomOut),
      const SizedBox(width: 3),
      GestureDetector(
        onTap: onZoomReset,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: fontScale != 1.0 ? AppColors.gold.withOpacity(0.12) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: fontScale != 1.0 ? AppColors.gold : Colors.grey.shade300, width: 1),
          ),
          child: Text('${(fontScale * 100).round()}%',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: fontScale != 1.0 ? AppColors.gold : Colors.grey.shade600)),
        ),
      ),
      const SizedBox(width: 3),
      PBtn(icon: Icons.add_rounded, active: false, onTap: onZoomIn),
      const SizedBox(width: 6),
      _Divider(),
      const SizedBox(width: 6),
      Tooltip(
        message: showTajwid ? 'Tajwid Aktif · Tekan lama untuk panduan' : 'Tajwid Mati · Tekan lama untuk panduan',
        child: GestureDetector(
          onLongPress: onTajwidLongPress,
          child: PBtn(
            icon: Icons.color_lens_outlined,
            active: showTajwid,
            onTap: onToggleTajwid,
          ),
        ),
      ),
      const SizedBox(width: 6),
      _Divider(),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(reciter,
          style: TextStyle(fontSize: 10, color: AppColors.dark, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis),
        if (playing)
          Text('$surahName · Ayat $playVerse',
            style: TextStyle(fontSize: 9, color: AppColors.gold))
        else if (showTajwid)
          Text('Tajwid aktif · tekan lama untuk panduan',
            style: TextStyle(fontSize: 9, color: tajwidColors['qalqalah']!)),
      ])),
      Text('Hal. $pageNum', style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.45))),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 24, color: AppColors.gold.withOpacity(0.25));
}

// ─────────────────────────────────────────────────────────────────────────────
// PBtn  (player button)
// ─────────────────────────────────────────────────────────────────────────────
class PBtn extends StatelessWidget {
  final IconData icon; final bool active; final VoidCallback onTap;
  const PBtn({super.key, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(
        color: active ? AppColors.gold.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? AppColors.gold : Colors.grey.shade300, width: 1)),
      child: Icon(icon, size: 17, color: active ? AppColors.gold : Colors.grey.shade600)));
}

// ─────────────────────────────────────────────────────────────────────────────
// NBtn  (navigation button – used in Drawer)
// ─────────────────────────────────────────────────────────────────────────────
class NBtn extends StatelessWidget {
  final String label; final IconData icon; final bool active; final VoidCallback onTap;
  const NBtn({super.key, required this.label,required this.icon,required this.active,required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child:GestureDetector(onTap:onTap,
      child:AnimatedContainer(duration:const Duration(milliseconds:200),
        padding:const EdgeInsets.symmetric(vertical:9),
        decoration:BoxDecoration(
          color:active?AppColors.dark:AppColors.gold.withOpacity(0.12),
          borderRadius:BorderRadius.circular(10),
          border:Border.all(color:active?AppColors.dark:AppColors.gold.withOpacity(0.4),width:1)),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Icon(icon,size:17,color:active?Colors.white:AppColors.dark),
          const SizedBox(height:3),
          Text(label,style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:active?Colors.white:AppColors.dark)),
        ]))));
}

// ─────────────────────────────────────────────────────────────────────────────
// DB  (diamond badge – used in Drawer lists)
// ─────────────────────────────────────────────────────────────────────────────
class DB extends StatelessWidget {
  final int n; final bool active;
  const DB({super.key, required this.n,required this.active});
  @override
  Widget build(BuildContext context) => SizedBox(width:32,height:32,
    child:CustomPaint(painter:_DBP(active:active),
      child:Center(child:Text('$n',style:TextStyle(fontSize:10,
        fontWeight:FontWeight.bold,color:active?AppColors.gold:AppColors.dark.withOpacity(0.7))))));
}

class _DBP extends CustomPainter {
  final bool active;
  const _DBP({required this.active});
  @override
  void paint(Canvas canvas, Size size) {
    final cx=size.width/2; final cy=size.height/2; final r=size.width/2-1;
    final path=Path()..moveTo(cx,cy-r)..lineTo(cx+r,cy)..lineTo(cx,cy+r)..lineTo(cx-r,cy)..close();
    canvas.drawPath(path,Paint()..color=(active?AppColors.gold.withOpacity(0.15):AppColors.gold.withOpacity(0.08))..style=PaintingStyle.fill);
    canvas.drawPath(path,Paint()..color=(active?AppColors.gold:AppColors.gold.withOpacity(0.5))..style=PaintingStyle.stroke..strokeWidth=1.2);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}
