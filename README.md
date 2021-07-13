# cnn open과 ov7670 연결하기

## 참조
이 프로젝트에 사용된 Lenet inference 베릴로그 코드는 아래의 출처에서 가져왔습니다.
- https://github.com/lulinchen/cnn_open

이 프로젝트에 사용된 ov7670 to vga 시스템 베릴로그 디자인은 아래 출처의 코드를 참조하여 작성하였습니다.
- http://www.nazim.ru/2512

## 시작하기
이 프로젝트는 아래의 환경을 기반으로 작성되었습니다.
- Windows 10
- Vivado Design Suite 2019.1
- Xilinx Zedboard
- VGA to VGA 포트와 VGA 인풋이 있는 모니터

또한 추가적으로 아래의 환경에서도 정상적으로 작동하는 것을 확인하였습니다.
- Ubuntu 20.04
- Vivado Design Suite 2018.3 / 2019.1
- Xilinx Zedboard
- VGA to VGA port with monitor

코드가 크게 복잡하지 않기 때문에, 다른 환경에서도 잘 작동할 것이라고 생각합니다.

## 1. 프로젝트 생성하기

### 1. 새 비바도 프로젝트 생성하기

1. Vivado Design Suite를 켜서 'Quick start'에 있는 'Create Project'를 클릭하세요.
2. 프로젝트 타입은 RTL Project로 설정하세요.
3. Add source 페이지에서, 이 디렉토리에 있는 시스템베릴로그 파일(.sv 파일)을 모두 추가하세요.
4. Add constraints 페이지에서는 zed_board.xdc 파일을 추가하세요.
5. Default part에서는 왼쪽 상단의 'boards'를 클릭한 후에, zedboard를 검색하여 선택하세요.
6. 마지막 페이지에서 finish를 누르면 새 비바도 프로젝트가 생성될 것입니다.


### 2. Add Xilinx IPs for project.

이 프로젝트에서는 클락 및 메모리와 관련된 Xilinx ip를 사용합니다. 
사용되는 ip는 아래와 같습니다.

- clock wizard 한 개
- block memory generator 세 개

왼쪽의 'Flow Navigator'/'PROJECT MANAGER'/'IP Catalog'를 클릭하면 ip catalog를 열 수 있습니다. 
Ip catalog에서 해당하는 ip를 찾아 아래의 설정을 참고하여 xilinx ip를 생성하십시오.

1. Clocking wizard 생성

이 clocking wizard는 zedboard clock을 받아, 다양한 frequency의 clock으로 바꾸어줍니다.
	- Component Name : clk_wiz_0(이 이름은 프로젝트 내에서 첫 번째로 clock wizard를 생성할 경우 기본으로 지정되는 이름입니다.)
	- Input Clock : name - clk_in_wiz / frequency - 100MHz
	- Output Clock1 : name - clk_100wiz / frequency - 100MHz
	- Output Clock2 : name - clk_75wiz / frequency - 75MHz
	- Output Clock3 : name - clk_50wiz / frequency - 50MHz
	- Output Clock4 : name - clk_25wiz / frequency - 25MHz

2. 첫번째 block memeory generator 생성

이 block memory는 ov7670_capture에서 보내 준 이미지를 저장하고 cv_core로 보내줍니다.
	- Component Name : blk_mem_gen_0(this is default name if you create clocking wizard for first time)
	- Memory Type : Simple Dual Port RAM
	- Port A Options : Port A Width - 8 / Port A Depth - 307200 / Enable Port Type - Always Enabled
	- Port B Options : Port B Width - 8 / Port B Depth - 307200 / Enable Port Type - Always Enabled

3. 두번째 block memeory generator 생성

이 block memory는 cv_core에서 보내 준 이미지를 저장하여 vga로 보내줍니다.
  - Component Name : blk_mem_gen_1(this is default name if you create clocking wizard for second time)
	- Memory Type : Simple Dual Port RAM
	- Port A Options : Port A Width - 4 / Port A Depth - 307200 / Enable Port Type - Always Enabled
	- Port B Options : Port B Width - 4 / Port B Depth - 307200 / Enable Port Type - Always Enabled

4. 세번째 block memeory generator 생성

이 block memory는 cv_core에서 보내 준 lenet의 input으로 사용될 이미지를 저장하여 lenet으로 보내줍니다.
	- Component Name : blk_mem_gen_2(this is default name if you create clocking wizard for third time)
	- Memory Type : Simple Dual Port RAM
	- Port A Options : Port A Width - 16 / Port A Depth - 1024 / Enable Port Type - Always Enabled
	- Port B Options : Port B Width - 16 / Port A Depth - 1024 / Enable Port Type - Use ENB Pin

### 3. Bitstream 생성하기

Bitstream을 생성하기에 앞서, synthesis와 implementation이 되어 있어야 합니다.
Vivado에서는 'generate bitstream'을 클릭하면, synthesis와 implementation을 먼저 하겠냐고 제안하므로,
간단하게 generate bitstream 버튼만 눌러주시면 됩니다.

## 2. 하드웨어 연결하기

### 1. OV7670 카메라와 Zedboard 연결하기

연결을 위해서는 F/M 소켓 점퍼 케이블이 20개 필요합니다. 아래의 표를 참조하여 연결해주세요.

|ov7670|Zedboard|Zynq|Verilog|
|--------|--------|--------|--------|
|PWDN|JA1|Y11|OV7670_PWDN|
|D0|JA2|AA11|OV7670_D[0]|
|D2|JA3|Y10|OV7670_D[2]|
|D4|JA4|AA9|OV7670_D[4]|
|GND|JA5|GROUND|GND|
|3V3|JA6|3.3V|3.3V|
|RESET|JA7|AB11|OV7670_RESET|
|D1|JA8|AB10|OV7670_D[1]|
|D3|JA9|AB9|OV7670_D[3]|
|D5|JA10|AA8|OV7670_D[5]|
|-|-|-|-|
|D6|JB1|W12|OV7670_D[6]|
|MCLK|JB2|W11|OV7670_XCLK|
|HREF|JB3|V10|OV7670_HREF|
|SIOD|JB4|W8|OV7670_SIOD|
|-|JB5|-|-|
|-|JB6|-|-|
|D7|JB7|V12|OV7670_D[7]|
|PCLK|JB8|W10|OV7670_PCLK|
|VSYNC|JB9|V9|OV7670_VSYNC|
|SIOC|JB10|V8|OV7670_SIOC|

### 2. Zedboard와 PC 연결하기

USB 2.0 포트가 있는 케이블을 통해 JTAG 포트를 이용해 연결하면 됩니다.

### 3. Connect Zedobard to Monitor

이 프로젝트에서는 이미지 출력을 위해 VGA output을 사용합니다. Zedboard와 모니터를 Zedboard의 VGA 포트를 사용하여 연결해주십시오.
제 경우에는 VGA to VGA 케이블을 사용하였지만, VGA to HDML나 VGA to DPI 와 같은 다른 케이블도 사용 가능하리라 생각합니다.

## 3. Zedboard에 Bitstream 올리기

### 1. Zedboard 켜기

Zedboard를 켜세요. 위의 연결이 잘 되어있는지 눈으로 확인하세요.

### 2. Hardware manager 열기

왼쪽의 'PROGRAM AND DEBUG' / 'Open Hardware Manager'를 클릭하세요.

### 3. Open target

상단 연두색 배너에서 'Open target'을 클릭하고, 'Auto Connect'를 클릭하세요.
Vivado가 pc에 연결된 zedboard를 자동으로 찾아 줄 것입니다.

### 4. Bitstream 업로드

상단 연두색 배너에서 'Program Device'를 클릭하세요. 
Vivado가 자동으로 프로젝트에서 생성된 bitstream 파일을 지정해두었을 것입니다.
'Program'을 클릭해서 bitstream을 zedboard에 업로드하세요.

Bitstream이 올라가고 촬영 화면이 잘 나오는지 확인하세요.
아래의 스위치와 버튼 설명을 참조하며, 스위치와 버튼을 제어해 보세요.

## 5. 디자인

### 1. 스위치와 버튼

swtich 7 : on - 중앙의 해상도를 바꾸고, inference 실행  / off - 아무것도 안함

switch 6 : on - 촬영 멈추기 				                    / off - 아무것도 안함

switch 5 : on - 중앙 부분에 녹색 테두리 생성 		        / off - 아무것도 안함

switch 4 : on - inference 결과 출력                   / off - 아무것도 안함

btnc : 하드웨어 리셋
