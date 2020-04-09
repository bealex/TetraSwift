#ifndef __SSD1306_H__
#define __SSD1306_H__

// адрес дисплея
constexpr uint8_t SSD1306_ADDRESS = 0x3C;

// установка контрастности, за данной командой должен быть отправлен байт контрастности от 00 до FF (по умолчанию 0x7F)
constexpr uint8_t SSD1306_SET_CONTRAST = 0x81;

// включить  изображение
constexpr uint8_t SSD1306_RAM_ON = 0xA4;

// выключить изображение
constexpr uint8_t SSD1306_RAM_OFF = 0xA5;

// пиксель установленный в 1 будет светиться
constexpr uint8_t SSD1306_INVERT_OFF = 0xA6;

// пиксель установленный в 1 будет выключен
constexpr uint8_t SSD1306_INVERT_ON = 0xA7;

// выключить дисплей
constexpr uint8_t SSD1306_DISPLAY_OFF = 0xAE;

// включить  дисплей
constexpr uint8_t SSD1306_DISPLAY_ON = 0xAF;

// пустая команда
constexpr uint8_t SSD1306_NOP = 0xE3;

// включить  прокрутку
constexpr uint8_t SSD1306_SCROLL_ON = 0x2F;

// выключить  прокрутку
constexpr uint8_t SSD1306_SCROLL_OFF = 0x2E;

// настройка непрерывной горизонтальной прокрутки вправо. За данной командой должны быть отправлены 6 байт настроек
constexpr uint8_t SSD1306_SCROLL_HORIZONTAL_RIGHT = 0x26;

// настройка непрерывной горизонтальной прокрутки влево. За данной командой должны быть отправлены 6 байт настроек
constexpr uint8_t SSD1306_SCROLL_HORIZONTAL_LEFT = 0x27;

// настройка непрерывной диагональной прокрутки вправо. За данной командой должны быть отправлены 5 байт настроек
constexpr uint8_t SSD1306_SCROLL_DIAGONAL_RIGHT = 0x29;

// настройка непрерывной диагональной прокрутки влево. За данной командой должны быть отправлены 5 байт настроек
constexpr uint8_t SSD1306_SCROLL_DIAGONAL_LEFT = 0x2A;

// настройка непрерывной вертикальной прокрутки. За данной командой должны быть отправлены 2 байта настроек
constexpr uint8_t SSD1306_SCROLL_VERTICAL = 0xA3;

// установка младшей части адреса колонки на странице
// у данной команды младщие четыре бита должны быть изменены на младшие биты адреса
// комадна предназначена только для режима страничной адресации
constexpr uint8_t SSD1306_ADDR_COLUMN_LBS = 0x00;

// установка старшей части адреса колонки на странице
// у данной команды младщие четыре бита должны быть изменены на старшие биты адреса
// комадна предназначена только для режима страничной адресации
constexpr uint8_t SSD1306_ADDR_COLUMN_MBS = 0x10;

// выбор режима адресации
// за данной командой должен быть отправлен байт младшие биты которого определяют режим:
// 00-горизонтальная (с переходом на новую страницу (строку))
// 01-вертикальная (с переходом на новую колонку)
// 10-страничная (только по выбранной странице)
constexpr uint8_t SSD1306_ADDR_MODE = 0x20;

// установка адреса колонки
// за данной командой должны быть отправлены два байта: начальный адрес и конечный адрес
// так можно определить размер экрана в колонках по ширине
constexpr uint8_t SSD1306_ADDR_COLUMN = 0x21;

// установка адреса страницы
// за данной командой должны быть отправлены два байта: начальный адрес и конечный адрес
// так можно определить размер экрана в строках по высоте
constexpr uint8_t SSD1306_ADDR_PAGE = 0x22;

// установка номера страницы которая будет выбрана для режима страничной адресации
// у данной команды младщие три бита должны быть изменены на номер страницы
// комадна предназначена только для режима страничной адресации
constexpr uint8_t SSD1306_ADDR_ONE_PAGE = 0xB0;

// установить начальный адрес ОЗУ (смещение памяти)
// у данной команды младщие шесть битов должны быть изменены на начальный адрес ОЗУ
constexpr uint8_t SSD1306_SET_START_LINE = 0x40;

// установить режим строчной развёртки справа-налево
constexpr uint8_t SSD1306_SET_REMAP_R_TO_L = 0xA0;

// установить режим строчной развёртки слева-направо
constexpr uint8_t SSD1306_SET_REMAP_L_TO_R = 0xA1;

// установить multiplex ratio (количество используемых выводов COM для вывода данных на дисплей)
// за данной командой должен быть отправлен один байт с указанием количества COM выводов (от 15 до 63)
constexpr uint8_t SSD1306_SET_MULTIPLEX_RATIO = 0xA8;

// установить режим кадровой развёртки снизу-верх
constexpr uint8_t SSD1306_SET_REMAP_D_TO_T = 0xC0;

// установить режим кадровой развёртки сверху-вниз
constexpr uint8_t SSD1306_SET_REMAP_T_TO_D = 0xC8;

// установить смещение дисплея
// за данной командой должен быть отправлен один байт с указанием вертикального сдвига чтения выходов COM (от 0 до 63).
constexpr uint8_t SSD1306_SET_DISPLAY_OFFSET = 0xD3;

// установить тип аппаратной конфигурации COM выводов
// за данной командой должен быть отправлен один байт, у которого:
// четвёртый бит: 0-последовательная / 1-альтернативная
// пятый бит: 0-отключить COM Left/Right remap / 1-включить COM Left/Right remap
constexpr uint8_t SSD1306_SET_COM_PINS = 0xDA;

// установить частоту обновления дисплея
// за данной командой должен быть отправлен один байт, старшие четыре бита которого определяют частоту, а младшие делитель
constexpr uint8_t SSD1306_SET_DISPLAY_CLOCK = 0xD5;

// установить фазы DC/DC преобразователя
// за данной командой должен быть отправлен один байт, старшие четыре бита которого определяют период, а младшие период
constexpr uint8_t SSD1306_SET_PRECHARGE_PERIOD = 0xD9;

// установить VcomH (влияет на яркость)
// за данной командой должен быть отправлен один байт, старшие четыре бита которого определяют напряжение
// пример: 0000 - VcomH=0.65Vcc, 0010 - VcomH=0.77Vcc, 0011 - VcomH=0.83Vcc и т.д.
constexpr uint8_t SSD1306_SET_VCOM_DESELECT = 0xDB;

// управление DC/DC преобразователем
// за данной командой должен быть отправлен один байт:
// 0x10 - отключить (VCC подается извне), 0x14 - запустить внутренний DC/DC
constexpr uint8_t SSD1306_CHARGE_DCDC_PUMP = 0x8D;

// положение бита DC в командном байте
// этот бит указывает что следующим байтом будет: 0-команда или 1-данные
constexpr uint8_t SSD1306_SHIFT_DC = 0x06;

// положение бита CO в командном байте
// этот бит указывает что после следующего байта (команды или данных) будет следовать (если будет): 0-байт данных или 1-новый командный байт
constexpr uint8_t SSD1306_SHIFT_CO = 0x07;

// (CO=0, DC=0) => 0x00 контрольный байт после которого следует байт команды
constexpr uint8_t SSD1306_COMMAND = (0 << SSD1306_SHIFT_CO) | (0 << SSD1306_SHIFT_DC);

// (CO=0, DC=1) => 0x40 контрольный байт после которого следует байт данных
constexpr uint8_t SSD1306_DATA = (0 << SSD1306_SHIFT_CO) | (1 << SSD1306_SHIFT_DC);

#endif
