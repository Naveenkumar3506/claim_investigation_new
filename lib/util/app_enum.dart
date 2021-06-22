enum MimeMediaType { image, video, pdf, excel, audio }

class MimeTypeHelper {
  static MimeMediaType determineFromURL(String url) {
    if (url.contains(".jpg") || url.contains(".png")) {
      return MimeMediaType.image;
    } else if (url.contains(".mov") ||
        url.contains(".mp4") ||
        url.contains(".avi")) {
      return MimeMediaType.video;
    } else if (url.contains(".pdf")) {
      return MimeMediaType.pdf;
    }
  }
}

enum Options { yes, no }

class OptionsHelper {
  static String getTitle(Options type) {
    switch (type) {
      case Options.yes:
        return "Yes";
      case Options.no:
        return "No";
      default:
        return "";
    }
  }
}

enum EmployeeOptions { selfEmployed, salaried }

class EmployeeOptionsHelper {
  static String getTitle(EmployeeOptions type) {
    switch (type) {
      case EmployeeOptions.selfEmployed:
        return "Self Employed";
      case EmployeeOptions.salaried:
        return "Salaried";
      default:
        return "";
    }
  }
}

enum PIVScenarios { one, two, three, four, five, six, seven }

class PIVScenarioHelper {
  static String getTitle(PIVScenarios type) {
    switch (type) {
      case PIVScenarios.one:
        return "Life Assured is Alive and in Good Health (Link)";
      case PIVScenarios.two:
        return "Life Assured is Alive & Un Healthy";
      case PIVScenarios.three:
        return "Life Assured is Deceased";
      case PIVScenarios.four:
        return "Life assured’s Address not traceable";
      case PIVScenarios.five:
        return "Life assured shifted from address";
      case PIVScenarios.six:
        return "Fraud (Existence not confirmed/ identity not established/Impersonation/ Pre-Policy death, Fake-Death)";
      case PIVScenarios.seven:
        return "Life Assured refused to meet/ denied for verification";
      // case PIVScenarios.eight:
      //   return "Others";
      default:
        return "";
    }
  }

  static PIVScenarios getScenarioFromString(String type) {
    switch (type) {
      case "Life Assured is Alive and in Good Health (Link)":
        return PIVScenarios.one;
      case "Life Assured is Alive & Un Healthy":
        return PIVScenarios.two;
      case "Life Assured is Deceased":
        return PIVScenarios.three;
      case "Life assured’s Address not traceable":
        return PIVScenarios.four;
      case "Life assured shifted from address":
        return PIVScenarios.five;
      case "Fraud (Existence not confirmed/ identity not established/Impersonation/ Pre-Policy death, Fake-Death)":
        return PIVScenarios.six;
      case "Life Assured refused to meet/ denied for verification":
        return PIVScenarios.seven;
      default:
        return PIVScenarios.one;
    }
  }
}
