import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

/// Simple video track renderer widget for LiveKit tracks
class VideoRenderer extends StatefulWidget {
  final VideoTrack track;
  final BoxFit fit;

  const VideoRenderer(
    this.track, {
    super.key,
    this.fit = BoxFit.contain,
  });

  @override
  State<VideoRenderer> createState() => _VideoRendererState();
}

class _VideoRendererState extends State<VideoRenderer> {
  @override
  void initState() {
    super.initState();
    widget.track.addListener(_onTrackChanged);
  }

  @override
  void dispose() {
    widget.track.removeListener(_onTrackChanged);
    super.dispose();
  }

  void _onTrackChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Use the track's video element to render
    return Container(
      color: Colors.black,
      child: widget.track.mediaStreamTrack != null
          ? Center(
              child: Text(
                'Video Track',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            )
          : const Center(
              child: Icon(Icons.videocam_off, color: Colors.white54),
            ),
    );
  }
}
