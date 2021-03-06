
enum MimeMediaType { image, video, pdf }

class MimeTypeHelper {
  static MimeMediaType determineFromURL(String url) {
    if (url.contains(".jpg") || url.contains(".png")) {
      return MimeMediaType.image;
    } else if (url.contains(".mov") || url.contains(".mp4") || url.contains(".avi")) {
      return MimeMediaType.video;
    } else if (url.contains(".pdf")) {
      return MimeMediaType.pdf;
    }
  }
}