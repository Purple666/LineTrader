//+------------------------------------------------------------------+
//|                                                       HLLine.mq4 |
//|                                                               rf |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "rf"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

// TODO: show MA

enum mode {
  SMA = MODE_SMA,
  EMA = MODE_EMA,
  // TODO: support swing high low
};
input mode 種別 = SMA;
input int 計算期間 = 20;
input int 表示期間 = 288;
input color 高値線の色 = clrTomato;
input color 安値線の色 = clrAqua;

int ma_method = 種別;
int ma_period = 計算期間;
int indicator_period = 表示期間;
color high_line_color = 高値線の色;
color low_line_color = 安値線の色;

// TODO: use variable length array
int lines_count = 0;
string line_names[];
void add_line_name(string name) {
  arrange_array_size(line_names, lines_count + 1);
  line_names[lines_count++] = name;
}
void arrange_array_size(string &xs[], int size) {
  int as = ArraySize(xs);
  if (size <= as) {
    return;
  }
  ArrayResize(xs, (as == 0) ? 10 : as * 2);
}

void OnInit() {
}

void OnDeinit(const int reason) {
  for (int i = 0; i < lines_count; i++) {
    ObjectDelete(line_names[i]);
  }
}

int OnCalculate(
  const int rates_total,
  const int prev_calculated,
  const datetime &time[],
  const double &open[],
  const double &high[],
  const double &low[],
  const double &close[],
  const long &tick_volume[],
  const long &volume[],
  const int &spread[]
) {
  if (rates_total == prev_calculated) {
    return rates_total;
  }
  int num = indicator_period;
  HL prev1 = 0;
  HL prev2 = 0;
  double value = -1;
  datetime start = time[num - 1];
  for (int i = 0; i < num; i++) {
    int index = num - i + 1;
    HL hl = get_hl(index, high[index], low[index]);
    // TODO: 3 nested switch is hard to understand
    switch (hl) {
    case HL_HIGH:
      switch (prev1) {
      case HL_HIGH:
        if (value < 0 || value < high[index]) {
          value = high[index];
        }
        break;
      case HL_MID:
        if (prev2 == HL_HIGH) {
          create_line(HL_LOW, value, start, time[index]);
          start = time[index];
          value = high[index];
        } else if (value < 0 || value < high[index]) {
          value = high[index];
        }
        prev2 = HL_MID;
        prev1 = HL_HIGH;
        break;
      case HL_LOW:
        create_line(HL_LOW, value, start, time[index]);
        prev2 = HL_LOW;
        prev1 = HL_HIGH;
        start = time[index];
        value = high[index];
        break;
      default:
        break;
      }
      break;
    case HL_MID:
      switch (prev1) {
      case HL_HIGH:
        create_line(HL_HIGH, value, start, time[index]);
        prev2 = HL_HIGH;
        prev1 = HL_MID;
        start = time[index];
        value = low[index];
        break;
      case HL_MID:
        switch (prev2) {
        case HL_HIGH:
          if (value < 0 || low[index] < value) {
            value = low[index];
          }
          break;
        case HL_LOW:
          if (value < 0 || value < high[index]) {
            value = high[index];
          }
          break;
        default:
          break;
        }
        break;
      case HL_LOW:
        create_line(HL_LOW, value, start, time[index]);
        prev2 = HL_LOW;
        prev1 = HL_MID;
        start = time[index];
        value = high[index];
        break;
      default:
        break;
      }
      break;
    case HL_LOW:
      switch (prev1) {
      case HL_HIGH:
        create_line(HL_HIGH, value, start, time[index]);
        prev2 = HL_HIGH;
        prev1 = HL_LOW;
        start = time[index];
        value = low[index];
        break;
      case HL_MID:
        if (prev2 == HL_LOW) {
          create_line(HL_HIGH, value, start, time[index]);
          start = time[index];
          value = low[index];
        } else if (value < 0 || low[index] < value) {
          value = low[index];
        }
        prev2 = HL_MID;
        prev1 = HL_LOW;
        break;
      case HL_LOW:
        if (value < 0 || low[index] < value) {
          value = low[index];
        }
        break;
      default:
        break;
      }
      break;
    default:
      break;
    }
  }
  return rates_total;
}

enum HL {
  HL_LOW = -1,
  HL_MID = 0,
  HL_HIGH = 1,
};

double get_ma(int index) {
  return iMA(Symbol(), PERIOD_CURRENT, ma_period, 0, ma_method, PRICE_CLOSE, index);
}
HL get_hl(int index, double high, double low) {
  double ma = get_ma(index);
  return (high < ma) ? HL_LOW : (ma < low) ? HL_HIGH : HL_MID;
}

void create_line(HL hl, double value, datetime start, datetime end) {
  if (hl == HL_MID) {
    return;
  }
  color cl = (hl == HL_LOW) ? low_line_color : high_line_color;
  string name = StringFormat("HLLine_%d_%d_%d", TimeLocal(), start, end);
  ObjectCreate(name, OBJ_TREND, 0, start, value, end, value);
  ObjectSet(name, OBJPROP_COLOR, cl);
  ObjectSet(name, OBJPROP_SELECTABLE, false);
  ObjectSet(name, OBJPROP_RAY_RIGHT, false);
  add_line_name(name);
}