import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'badge_inventory_screen.dart';
import 'game_provider.dart';
import 'models/game_question.dart';
import 'widgets/waste_card.dart';

// Class phụ để đóng gói dữ liệu đồng nhất cho mỗi loại rác
class WasteItemData {
  final String name;
  final String imagePath;
  final String funFact;

  WasteItemData({
    required this.name,
    required this.imagePath,
    required this.funFact,
  });
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Dữ liệu đã được chuẩn hóa: Gắn chặt Tên - Ảnh - Fact với nhau
  final Map<WasteCategory, List<WasteItemData>> _wasteDatabase = {
    WasteCategory.recyclable: [
      WasteItemData(name: 'Vỏ chai nhựa PET', imagePath: 'https://i.pinimg.com/736x/28/7b/91/287b913f6cc09b87d24175aa79d80571.jpg', funFact: 'Nhựa PET có thể tái chế thành sợi polyester để may quần áo.'),
      WasteItemData(name: 'Lon bia nhôm', imagePath: 'https://i.pinimg.com/736x/71/35/3d/71353d08a9e310051cec69d3dbd42013.jpg', funFact: 'Lon nhôm có thể tái chế vô hạn lần mà không giảm chất lượng.'),
      WasteItemData(name: 'Lon nước ngọt', imagePath: 'https://i.pinimg.com/736x/e0/72/15/e07215402e9b2691a6616e1c76495a7c.jpg', funFact: 'Tái chế 1 lon nước ngọt tiết kiệm đủ năng lượng để thắp sáng tivi trong 3 giờ.'),
      WasteItemData(name: 'Giấy báo cũ', imagePath: 'https://i.pinimg.com/1200x/a4/60/87/a4608752c8337ff88f7f22992fd1f3ca.jpg', funFact: 'Tái chế 1 tấn giấy cứu được 17 cây xanh trưởng thành.'),
      WasteItemData(name: 'Thùng carton', imagePath: 'https://i.pinimg.com/1200x/22/1b/dc/221bdcc9e515209255c06531800d7b36.jpg', funFact: 'Nên tháo dỡ và ép phẳng hộp carton để tiết kiệm diện tích thu gom.'),
      WasteItemData(name: 'Hộp giấy đựng giày', imagePath: 'https://i.pinimg.com/1200x/a6/17/9e/a6179e7a9f0f734d571d14f34abcf5ac.jpg', funFact: 'Giấy bìa cứng tái chế có thể làm thành lõi cuộn giấy vệ sinh mới.'),
      WasteItemData(name: 'Chai thủy tinh trắng', imagePath: 'https://i.pinimg.com/736x/f6/bb/8d/f6bb8d6f6638e0b75e728ff5fade185f.jpg', funFact: 'Thủy tinh mất tới 1 triệu năm để phân hủy tự nhiên nhưng lại tái chế được 100%.'),
      WasteItemData(name: 'Chai thủy tinh màu xanh', imagePath: 'https://i.pinimg.com/1200x/ca/fc/19/cafc197aa87478326c81241c1ad20f59.jpg', funFact: 'Thủy tinh màu được phân loại riêng để không làm hỏng màu của mẻ nấu mới.'),
      WasteItemData(name: 'Chai rượu vang', imagePath: 'https://i.pinimg.com/1200x/1c/f1/6e/1cf16ebb6d780e7b148adf1243ef00f7.jpg', funFact: 'Nút bần của chai vang làm từ gỗ sồi nên bỏ vào rác hữu cơ, còn chai thì tái chế.'),
      WasteItemData(name: 'Hộp sữa giấy', imagePath: 'https://i.pinimg.com/736x/c7/82/73/c782738d4a959bcf001c7477347bd429.jpg', funFact: 'Cần hút sạch sữa và làm bẹp hộp trước khi vứt để không sinh dòi bọ.'),
      WasteItemData(name: 'Lọ nhựa dầu gội', imagePath: 'https://i.pinimg.com/1200x/0e/9b/d6/0e9bd64722acdbe5aebdbb8f2f115287.jpg', funFact: 'Làm từ nhựa HDPE, loại nhựa rất dày dặn và có giá trị tái chế cao.'),
      WasteItemData(name: 'Lọ nhựa sữa tắm', imagePath: 'https://i.pinimg.com/1200x/77/12/7b/77127b11f76ad6badda676c4d2951b82.jpg', funFact: 'Hãy súc rửa sạch bọt xà phòng bên trong trước khi phân loại.'),
      WasteItemData(name: 'Vỏ chai nước mắm', imagePath: 'https://chailogiaxuong.com.vn/watermark/product/600x600x2/upload/product/chai-dung-nuoc-mam-500ml-3555.jpg', funFact: 'Mùi nước mắm có thể thu hút côn trùng, tráng qua nước là cách tốt nhất.'),
      WasteItemData(name: 'Vỏ chai dầu ăn', imagePath: 'https://i.pinimg.com/736x/53/9e/e5/539ee5cd65dc1c538e098e8b672f9d2a.jpg', funFact: 'Phải làm sạch dầu mỡ thừa tối đa để không làm bẩn dây chuyền nhựa.'),
      WasteItemData(name: 'Túi giấy kraft', imagePath: 'https://i.pinimg.com/736x/c9/2e/e6/c92ee66e95a15b59bb5959ba01cdb570.jpg', funFact: 'Túi giấy dễ phân hủy sinh học hơn túi nilon và rất dễ nghiền thành bột giấy.'),
      WasteItemData(name: 'Vỏ hộp bánh thiếc', imagePath: 'https://afamilycdn.com/150157425591193600/2024/1/6/5-0842-1704512674122-1704512674613677886622.jpg', funFact: 'Kim loại có từ tính như thiếc rất dễ được nam châm ở nhà máy hút để phân loại.'),
      WasteItemData(name: 'Lon sữa bò', imagePath: 'https://i.pinimg.com/1200x/b2/c4/3f/b2c43f3ad0b8a6c422622760416c9bab.jpg', funFact: 'Rửa sạch cặn sữa đặc ngọt lịm để kiến không bâu vào thùng rác tái chế.'),
      WasteItemData(name: 'Giấy A4 văn phòng', imagePath: 'https://i.pinimg.com/736x/f9/42/c5/f942c5fd905446e2fd61de582266182f.jpg', funFact: 'Giấy in trắng có chất lượng sợi giấy tốt nhất để tái chế thành giấy cao cấp.'),
      WasteItemData(name: 'Sách giáo khoa cũ', imagePath: 'https://i.pinimg.com/1200x/9e/b2/15/9eb2158690e51c368f1fadc2d1c1b51a.jpg', funFact: 'Quyên góp sách cũ cho trẻ em nghèo là cách tái sử dụng tốt nhất trước khi đem tái chế.'),
      WasteItemData(name: 'Tạp chí màu', imagePath: 'https://static.oreka.vn/800-800_b39e4679-cc8f-4375-b50d-4d76196c2360', funFact: 'Giấy bóng kính của tạp chí vẫn có thể tái chế được ở các nhà máy chuyên dụng.'),
      WasteItemData(name: 'Sổ tay cũ', imagePath: 'https://nik.edu.vn/wp-content/uploads/2017/07/6-cuon-so-1-nikedu.jpg', funFact: 'Nên tháo phần gáy lò xo kim loại để phân loại riêng với phần giấy.'),
      WasteItemData(name: 'Lõi giấy vệ sinh', imagePath: 'https://i.pinimg.com/1200x/73/9c/00/739c00069bc263bc15861cbc2ae15128.jpg', funFact: 'Phần lõi carton cứng này hoàn toàn có thể tái chế cùng với bìa thùng carton.'),
      WasteItemData(name: 'Bìa hồ sơ', imagePath: 'https://i.pinimg.com/1200x/c0/dc/f7/c0dcf7339a35867cf02f2a0557b87761.jpg', funFact: 'Nhớ tháo thanh ghim sắt nẹp tài liệu ra trước khi bỏ vào thùng rác giấy.'),
      WasteItemData(name: 'Bao thư giấy', imagePath: 'https://i.pinimg.com/1200x/7a/2a/d6/7a2ad6134ed85053572258090fa76554.jpg', funFact: 'Mảnh màng nilon trong suốt ở ô địa chỉ bao thư thường được máy tái chế lọc ra.'),
      WasteItemData(name: 'Tờ rơi quảng cáo', imagePath: 'https://i.pinimg.com/736x/16/be/11/16be113146820d976548ca1bee734209.jpg', funFact: 'Giấy in quảng cáo hoàn toàn có thể tái chế thành giấy vệ sinh hoặc khăn giấy.'),
      WasteItemData(name: 'Chảo nhôm hỏng', imagePath: 'https://i.pinimg.com/736x/a1/ee/8a/a1ee8ac5a8a098c96b93a99c40555e95.jpg', funFact: 'Đồ gia dụng kim loại cũ là nguồn nguyên liệu quý cho xưởng luyện kim.'),
      WasteItemData(name: 'Nồi inox hỏng', imagePath: 'https://cdn2.fptshop.com.vn/unsafe/Uploads/images/tin-tuc/159993/Originals/nguyen-nhan-noi-inox-nhanh-hong.jpg', funFact: 'Inox không gỉ có thể nung chảy để đúc thành sản phẩm mới bền bỉ không kém.'),
      WasteItemData(name: 'Muỗng inox', imagePath: 'https://c7.alamy.com/comp/MNRP77/two-metal-teaspoons-broken-in-half-and-serviceable-on-a-white-background-the-concept-of-individuality-in-society-and-the-family-MNRP77.jpg', funFact: 'Bất kỳ mảnh kim loại nào dù nhỏ cũng mang lại giá trị tái chế cao.'),
      WasteItemData(name: 'Nĩa inox', imagePath: 'https://c7.alamy.com/comp/D8WFX8/close-up-of-broken-fork-on-parquet-floor-D8WFX8.jpg', funFact: 'Hợp kim thép không gỉ được thu mua với giá khá cao tại các vựa phế liệu.'),
      WasteItemData(name: 'Mâm nhôm', imagePath: 'https://bichha.vn/media/product/5108_finish.jpg', funFact: 'Nhôm rất nhẹ và tốn ít năng lượng để nấu chảy hơn so với sản xuất nhôm từ quặng bauxite.'),
      WasteItemData(name: 'Chìa khóa đồng', imagePath: 'https://preview.redd.it/are-keys-worth-anything-to-recycle-v0-0x82r2piw3qe1.jpeg?width=1080&crop=smart&auto=webp&s=82bead81d3b09840af66039673ffc3cd2a1a8e24', funFact: 'Đồng thau (brass) có thể tái chế hoàn toàn mà không làm mất đặc tính vật lý.'),
      WasteItemData(name: 'Ống nhựa PVC', imagePath: 'https://file.hstatic.net/1000371548/article/thiet_ke_chua_co_tend_c3708940b9e9490f95466a8b6afd7e09.png', funFact: 'Vật liệu xây dựng bằng nhựa thường được băm nhỏ để đùn thành ống nước mới.'),
      WasteItemData(name: 'Dây điện lõi đồng', imagePath: 'https://forscrap.com/assets/cache/images/copper-wire-mix-480x360-6f4.webp', funFact: 'Phần vỏ nhựa và lõi đồng đều có máy bóc tách để tái chế riêng biệt.'),
      WasteItemData(name: 'Mắc áo nhôm', imagePath: 'https://preview.redd.it/how-to-remove-rust-stains-from-clothes-or-shirts-zoom-in-v0-pkw4rej711lg1.jpg?width=1080&crop=smart&auto=webp&s=40a9c1f67574b785722f65713b97a553a111f361', funFact: 'Kim loại uốn cong dễ dàng đóng cục để vận chuyển đến lò nấu.'),
      WasteItemData(name: 'Vỏ hộp ngũ cốc', imagePath: 'https://image.pollinations.ai/prompt/empty%20cereal%20box%20crushed?width=400&height=400&nologo=true', funFact: 'Chất liệu giấy bìa cứng này tái chế rất tốt, chỉ cần bóc lớp túi nilon bên trong.'),
      WasteItemData(name: 'Lõi cuộn băng keo', imagePath: 'https://image.pollinations.ai/prompt/empty%20tape%20roll%20cardboard?width=400&height=400&nologo=true', funFact: 'Được ép từ nhiều lớp giấy nén chặt, lõi băng keo nên bỏ chung với rác giấy tái chế.'),
      WasteItemData(name: 'Vỏ bình nước 20L', imagePath: 'https://image.pollinations.ai/prompt/empty%2020L%20water%20jug%20plastic?width=400&height=400&nologo=true', funFact: 'Thường làm từ nhựa PET hoặc PC, các bình thủng sẽ được băm thành hạt nhựa.'),
      WasteItemData(name: 'Thau nhựa cũ', imagePath: 'https://image.pollinations.ai/prompt/broken%20plastic%20basin?width=400&height=400&nologo=true', funFact: 'Nhựa cứng tái chế tốt hơn nhựa dùng một lần rất nhiều.'),
      WasteItemData(name: 'Rổ nhựa vỡ', imagePath: 'https://image.pollinations.ai/prompt/broken%20plastic%20basket?width=400&height=400&nologo=true', funFact: 'Cắt nhỏ hoặc đạp vỡ rổ hỏng sẽ giúp tiết kiệm không gian thùng rác.'),
      WasteItemData(name: 'Ghế nhựa gãy', imagePath: 'https://image.pollinations.ai/prompt/broken%20plastic%20chair?width=400&height=400&nologo=true', funFact: 'Ghế nhựa PP mang nung chảy có thể đúc lại thành hàng ngàn vật dụng khác.'),
      WasteItemData(name: 'Chai nhựa HDPE', imagePath: 'https://image.pollinations.ai/prompt/empty%20HDPE%20plastic%20bottle?width=400&height=400&nologo=true', funFact: 'Nhựa HDPE (thường có màu đục) có thể tái chế thành bàn ghế nhựa ngoài trời.'),
      WasteItemData(name: 'Vỏ hộp trà', imagePath: 'https://image.pollinations.ai/prompt/empty%20cardboard%20tea%20box?width=400&height=400&nologo=true', funFact: 'Bỏ lõi trà vào thùng rác hữu cơ và gập phẳng vỏ hộp trà ném vào thùng tái chế.'),
      WasteItemData(name: 'Túi giấy mua sắm', imagePath: 'https://image.pollinations.ai/prompt/crumpled%20paper%20shopping%20bag?width=400&height=400&nologo=true', funFact: 'Tháo phần quai xách bằng ruy băng hoặc dây dù trước khi đưa túi giấy đi tái chế.'),
      WasteItemData(name: 'Vỏ can nhựa 5L', imagePath: 'https://image.pollinations.ai/prompt/empty%205L%20plastic%20canister?width=400&height=400&nologo=true', funFact: 'Các can nhựa lớn cung cấp một lượng lớn hạt nhựa tái sinh khi được nghiền nát.'),
      WasteItemData(name: 'Hộp giấy pizza (phần nắp)', imagePath: 'https://image.pollinations.ai/prompt/clean%20pizza%20box%20lid?width=400&height=400&nologo=true', funFact: 'Phần nắp hộp sạch dầu mỡ hoàn toàn tái chế được, chỉ xé bỏ phần đáy dính phô mai.'),
      WasteItemData(name: 'Bìa lịch để bàn', imagePath: 'https://image.pollinations.ai/prompt/old%20desk%20calendar?width=400&height=400&nologo=true', funFact: 'Tháo gáy xoắn lò xo để giấy và kim loại được về đúng nơi quy định.'),
      WasteItemData(name: 'Thước kẻ nhựa', imagePath: 'https://image.pollinations.ai/prompt/broken%20plastic%20ruler?width=400&height=400&nologo=true', funFact: 'Các mảnh nhựa cứng vỡ từ đồ dùng học tập vẫn có thể nấu chảy lại.'),
      WasteItemData(name: 'Kẹp bướm kim loại', imagePath: 'https://image.pollinations.ai/prompt/binder%20clips%20scrap?width=400&height=400&nologo=true', funFact: 'Đừng vứt bừa, kim loại đen từ kẹp bướm luôn được các nhà máy gang thép thu mua.'),
      WasteItemData(name: 'Vỏ lon cá mòi', imagePath: 'https://image.pollinations.ai/prompt/empty%20sardine%20tin%20can?width=400&height=400&nologo=true', funFact: 'Hãy rửa sạch dầu mỡ và mùi tanh để không làm bẩn lô rác tái chế xung quanh.'),
      WasteItemData(name: 'Khay nhựa trái cây (PET)', imagePath: 'https://image.pollinations.ai/prompt/clear%20plastic%20fruit%20container?width=400&height=400&nologo=true', funFact: 'Nhựa PET trong suốt làm khay siêu thị có khả năng tái chế cao tương đương chai nước.'),
    ],
    WasteCategory.organic: [
      WasteItemData(name: 'Vỏ chuối', imagePath: 'https://image.pollinations.ai/prompt/banana%20peel%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ chuối phân hủy cực nhanh và bổ sung lượng lớn Kali cho đất trồng cây.'),
      WasteItemData(name: 'Cơm thừa', imagePath: 'https://image.pollinations.ai/prompt/leftover%20cooked%20rice%20waste?width=400&height=400&nologo=true', funFact: 'Cơm thừa có thể cho gia cầm ăn hoặc ủ thành phân hoai mục.'),
      WasteItemData(name: 'Vỏ dưa hấu', imagePath: 'https://image.pollinations.ai/prompt/watermelon%20rind%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ dưa hấu chứa nhiều nước, giúp tạo độ ẩm tự nhiên cho đống ủ phân compost.'),
      WasteItemData(name: 'Bã cà phê', imagePath: 'https://image.pollinations.ai/prompt/used%20coffee%20grounds%20waste?width=400&height=400&nologo=true', funFact: 'Bã cà phê rắc quanh vườn giúp xua đuổi ốc sên và giun đất rất thích chúng.'),
      WasteItemData(name: 'Vỏ trứng', imagePath: 'https://image.pollinations.ai/prompt/crushed%20egg%20shells%20waste?width=400&height=400&nologo=true', funFact: 'Nghiền nát vỏ trứng sẽ cung cấp canxi tuyệt vời giúp cây cà chua không bị thối rễ.'),
      WasteItemData(name: 'Lá cây khô', imagePath: 'https://image.pollinations.ai/prompt/dry%20leaves%20on%20ground?width=400&height=400&nologo=true', funFact: 'Lá khô cung cấp lượng nguyên tố carbon dồi dào để cân bằng hố ủ phân hữu cơ.'),
      WasteItemData(name: 'Bắp cải héo', imagePath: 'https://image.pollinations.ai/prompt/wilted%20cabbage%20leaves?width=400&height=400&nologo=true', funFact: 'Các loại rau lá xanh xẹp xuống và phân hủy chỉ sau vài ngày trong thùng rác ủ.'),
      WasteItemData(name: 'Vỏ cam', imagePath: 'https://image.pollinations.ai/prompt/orange%20peels%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ cam quýt ủ GE (enzyme rác) với đường nâu có thể tạo ra nước lau sàn tự nhiên.'),
      WasteItemData(name: 'Vỏ chanh', imagePath: 'https://image.pollinations.ai/prompt/squeezed%20lemon%20peels?width=400&height=400&nologo=true', funFact: 'Do chứa tinh dầu kháng khuẩn, vỏ chanh phân hủy chậm hơn các loại rác hữu cơ khác.'),
      WasteItemData(name: 'Lõi táo', imagePath: 'https://image.pollinations.ai/prompt/apple%20core%20waste?width=400&height=400&nologo=true', funFact: 'Lõi táo vứt ra tự nhiên mất khoảng 2 tháng để phân hủy hoàn toàn thành đất.'),
      WasteItemData(name: 'Bã trà', imagePath: 'https://image.pollinations.ai/prompt/used%20tea%20leaves%20waste?width=400&height=400&nologo=true', funFact: 'Bã trà tươi vùi dưới gốc cây hoa hồng giúp cây xanh lá và ra hoa đẹp hơn.'),
      WasteItemData(name: 'Xương cá', imagePath: 'https://image.pollinations.ai/prompt/fish%20bones%20waste?width=400&height=400&nologo=true', funFact: 'Xương cá giàu phốt pho, nhưng nên ủ kín để tránh thu hút ruồi nhặng và mùi hôi.'),
      WasteItemData(name: 'Xương gà', imagePath: 'https://image.pollinations.ai/prompt/chicken%20bones%20leftover?width=400&height=400&nologo=true', funFact: 'Xương động vật phân hủy rất lâu, cần hố ủ công nghiệp sinh nhiệt cao hoặc phải đập vụn.'),
      WasteItemData(name: 'Vỏ tôm', imagePath: 'https://image.pollinations.ai/prompt/shrimp%20shells%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ tôm chứa Chitin - một chất cải tạo đất tuyệt vời, kích thích vi sinh vật có lợi.'),
      WasteItemData(name: 'Bã mía', imagePath: 'https://image.pollinations.ai/prompt/chewed%20sugarcane%20bagasse?width=400&height=400&nologo=true', funFact: 'Bã mía là nguồn rác hữu cơ khô, tạo độ tơi xốp và thoáng khí cho luống ủ phân.'),
      WasteItemData(name: 'Vỏ sầu riêng', imagePath: 'https://image.pollinations.ai/prompt/durian%20shell%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ cực cứng và gai góc nên phân hủy siêu chậm, bạn cần chặt nhỏ trước khi ủ.'),
      WasteItemData(name: 'Vỏ dừa', imagePath: 'https://image.pollinations.ai/prompt/coconut%20husk%20waste?width=400&height=400&nologo=true', funFact: 'Xơ dừa xé nhỏ được xưởng nông nghiệp thu mua để làm giá thể trồng lan, nấm.'),
      WasteItemData(name: 'Vỏ lạc', imagePath: 'https://image.pollinations.ai/prompt/peanut%20shells%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ đậu phộng (lạc) rất xốp, thích hợp lót đáy chậu cây để chống úng nước.'),
      WasteItemData(name: 'Cọng hành', imagePath: 'https://image.pollinations.ai/prompt/green%20onion%20scraps?width=400&height=400&nologo=true', funFact: 'Phần gốc hành thừa thực ra có thể cắm xuống đất để mọc ra cây hành mới.'),
      WasteItemData(name: 'Rau muống héo', imagePath: 'https://image.pollinations.ai/prompt/wilted%20water%20spinach?width=400&height=400&nologo=true', funFact: 'Thân cây mọng nước nên vi khuẩn dễ dàng phân giải chúng thành chất lỏng mùn.'),
      WasteItemData(name: 'Cà chua hỏng', imagePath: 'https://image.pollinations.ai/prompt/rotten%20tomato%20waste?width=400&height=400&nologo=true', funFact: 'Đôi khi hạt cà chua trong rác ủ chưa bị tiêu hủy sẽ tự nảy mầm mọc thành cây non.'),
      WasteItemData(name: 'Khoai tây thối', imagePath: 'https://image.pollinations.ai/prompt/rotten%20potato%20waste?width=400&height=400&nologo=true', funFact: 'Tinh bột lên men của khoai tây cung cấp thức ăn dồi dào cho vi sinh vật ủ rác.'),
      WasteItemData(name: 'Vỏ hành tây', imagePath: 'https://image.pollinations.ai/prompt/onion%20skins%20waste?width=400&height=400&nologo=true', funFact: 'Lớp vỏ mỏng như giấy này tan vào đất cực nhanh mà không để lại dấu vết.'),
      WasteItemData(name: 'Vỏ tỏi', imagePath: 'https://image.pollinations.ai/prompt/garlic%20peels%20waste?width=400&height=400&nologo=true', funFact: 'Mùi hương của vỏ tỏi ủ rác có thể xua đuổi một số loại rệp hại rễ cây.'),
      WasteItemData(name: 'Gốc rau dền', imagePath: 'https://image.pollinations.ai/prompt/amaranth%20roots%20waste?width=400&height=400&nologo=true', funFact: 'Rễ cây xốp và chứa nhiều nitơ, giúp quá trình ủ compost sinh nhiệt nhanh hơn.'),
      WasteItemData(name: 'Bã đậu nành', imagePath: 'https://image.pollinations.ai/prompt/soybean%20okara%20waste?width=400&height=400&nologo=true', funFact: 'Bã đậu nành sau khi vắt sữa là nguồn đạm (protein) siêu tốc cho các loại hoa hồng.'),
      WasteItemData(name: 'Vỏ măng', imagePath: 'https://image.pollinations.ai/prompt/bamboo%20shoot%20peels%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ măng trúc khá dai và cứng, cần thời gian ủ dài hơn rau xanh thông thường.'),
      WasteItemData(name: 'Lá chuối', imagePath: 'https://image.pollinations.ai/prompt/dry%20banana%20leaves?width=400&height=400&nologo=true', funFact: 'Lá chuối phân hủy tốt, thường được người nông dân dùng để phủ luống chống cỏ dại.'),
      WasteItemData(name: 'Lá phong khô', imagePath: 'https://image.pollinations.ai/prompt/dry%20maple%20leaves?width=400&height=400&nologo=true', funFact: 'Rác sân vườn như lá rụng là nguyên liệu chủ đạo tạo nên lớp mùn đất tự nhiên màu mỡ.'),
      WasteItemData(name: 'Hoa hồng héo', imagePath: 'https://image.pollinations.ai/prompt/wilted%20red%20roses?width=400&height=400&nologo=true', funFact: 'Cánh hoa tươi héo đi tự nhiên phân hủy rất nhanh chóng và không sinh mùi khó chịu.'),
      WasteItemData(name: 'Hoa cúc tàn', imagePath: 'https://image.pollinations.ai/prompt/dead%20chrysanthemum%20flowers?width=400&height=400&nologo=true', funFact: 'Nên rút bỏ các sợi kẽm định hình trên hoa trước khi bỏ vào thùng rác hữu cơ.'),
      WasteItemData(name: 'Cỏ xén', imagePath: 'https://image.pollinations.ai/prompt/freshly%20cut%20grass%20clippings?width=400&height=400&nologo=true', funFact: 'Cỏ tươi chứa lượng lớn nitơ, nếu chất thành đống sẽ bốc hơi nóng hầm hập do lên men.'),
      WasteItemData(name: 'Vỏ hạt dưa', imagePath: 'https://image.pollinations.ai/prompt/melon%20seed%20shells?width=400&height=400&nologo=true', funFact: 'Rác từ các ngày lễ Tết này thường được vùi vào đất để tạo độ tơi xốp.'),
      WasteItemData(name: 'Vỏ bưởi', imagePath: 'https://image.pollinations.ai/prompt/pomelo%20peel%20waste?width=400&height=400&nologo=true', funFact: 'Ngoài làm rác ủ, vỏ bưởi còn có thể đun nước gội đầu hoặc phơi khô đốt đuổi muỗi.'),
      WasteItemData(name: 'Vỏ quýt', imagePath: 'https://image.pollinations.ai/prompt/tangerine%20peel%20waste?width=400&height=400&nologo=true', funFact: 'Tinh dầu quýt kìm hãm nấm mốc, nên rải đều vỏ quýt thay vì dồn cục trong hố ủ.'),
      WasteItemData(name: 'Cùi bưởi', imagePath: 'https://image.pollinations.ai/prompt/white%20pith%20of%20pomelo?width=400&height=400&nologo=true', funFact: 'Phần xốp trắng lưu giữ độ ẩm rất tốt, giúp hố ủ phân compost không bị khô hạn.'),
      WasteItemData(name: 'Lõi ngô', imagePath: 'https://image.pollinations.ai/prompt/corn%20cobs%20waste?width=400&height=400&nologo=true', funFact: 'Lõi ngô rất cứng, đôi khi người ta phơi khô để làm củi đun hoặc làm than không khói.'),
      WasteItemData(name: 'Bã rượu', imagePath: 'https://image.pollinations.ai/prompt/wine%20grape%20pomace%20waste?width=400&height=400&nologo=true', funFact: 'Chứa nấm men tự nhiên giúp đống ủ rác nóng lên và phân hủy bã thực vật thần tốc.'),
      WasteItemData(name: 'Vỏ sò', imagePath: 'https://image.pollinations.ai/prompt/seashells%20waste?width=400&height=400&nologo=true', funFact: 'Đập vụn vỏ sò rắc lên đất giúp cân bằng độ pH, làm giảm độ chua của đất.'),
      WasteItemData(name: 'Vỏ hàu', imagePath: 'https://image.pollinations.ai/prompt/oyster%20shells%20waste?width=400&height=400&nologo=true', funFact: 'Canxi cacbonat trong vỏ hàu tồn tại rất lâu và là lớp lọc nước sinh học tự nhiên.'),
      WasteItemData(name: 'Bã thuốc bắc', imagePath: 'https://image.pollinations.ai/prompt/boiled%20herbal%20medicine%20dregs?width=400&height=400&nologo=true', funFact: 'Bã các loại lá cây thuốc nam/bắc đun xong cực kỳ giàu dược tính để làm phân bón lót.'),
      WasteItemData(name: 'Bánh mì mốc', imagePath: 'https://image.pollinations.ai/prompt/moldy%20bread%20slice?width=400&height=400&nologo=true', funFact: 'Các loại tinh bột mốc có thể làm mồi nhử cho nấm và vi sinh vật phân hủy trong hố ủ.'),
      WasteItemData(name: 'Cơm dừa nạo', imagePath: 'https://image.pollinations.ai/prompt/grated%20coconut%20residue?width=400&height=400&nologo=true', funFact: 'Bã dừa dễ bị mốc trắng do lượng béo còn sót, nên cần vùi sâu dưới lớp đất khi bón.'),
      WasteItemData(name: 'Xác sắn dây', imagePath: 'https://image.pollinations.ai/prompt/cassava%20residue%20waste?width=400&height=400&nologo=true', funFact: 'Sau khi lọc lấy tinh bột, phần xác xơ sắn là chất tạo mùn tơi xốp tuyệt vời.'),
      WasteItemData(name: 'Nước vo gạo chua', imagePath: 'https://image.pollinations.ai/prompt/fermented%20rice%20water?width=400&height=400&nologo=true', funFact: 'Dù ở dạng lỏng, đây là nguồn vi khuẩn lactic hữu cơ để tưới kích rễ cây rất tốt.'),
      WasteItemData(name: 'Dưa hấu hỏng', imagePath: 'https://image.pollinations.ai/prompt/rotten%20watermelon?width=400&height=400&nologo=true', funFact: 'Trái cây ngọt lên men sẽ thu hút ruồi lính đen - một loài phàm ăn có lợi cho tiêu hủy rác.'),
      WasteItemData(name: 'Đu đủ thối', imagePath: 'https://image.pollinations.ai/prompt/rotten%20papaya?width=400&height=400&nologo=true', funFact: 'Đu đủ chứa enzyme papain phá vỡ protein nhanh, giúp thúc đẩy quá trình ủ rác.'),
      WasteItemData(name: 'Vỏ nhãn', imagePath: 'https://image.pollinations.ai/prompt/longan%20peels%20waste?width=400&height=400&nologo=true', funFact: 'Vỏ và hạt nhãn chôn vào đất có thể tạo khoảng trống giúp đất thoát nước tốt hơn.'),
      WasteItemData(name: 'Vỏ vải', imagePath: 'https://image.pollinations.ai/prompt/lychee%20peels%20waste?width=400&height=400&nologo=true', funFact: 'Thuộc nhóm rác hữu cơ khô, ít gây mùi khó chịu khi ủ bồn ngoài ban công.'),
      WasteItemData(name: 'Hạt xoài', imagePath: 'https://image.pollinations.ai/prompt/mango%20seed%20waste?width=400&height=400&nologo=true', funFact: 'Phần xơ bao quanh hạt dễ phân hủy, nhưng cái hột cứng bên trong thì cần thời gian khá dài.'),
    ],
    WasteCategory.hazardous: [
      WasteItemData(name: 'Pin tiểu AA', imagePath: 'https://image.pollinations.ai/prompt/old%20AA%20batteries?width=400&height=400&nologo=true', funFact: 'Một viên pin nhỏ rỉ sét có thể làm ô nhiễm 500 lít nước ngầm chứa kẽm và mangan.'),
      WasteItemData(name: 'Pin AAA', imagePath: 'https://image.pollinations.ai/prompt/old%20AAA%20batteries?width=400&height=400&nologo=true', funFact: 'Đừng vứt sọt rác, hãy gom pin vào một chai nhựa rỗng và mang đến điểm thu hồi.'),
      WasteItemData(name: 'Pin cúc áo', imagePath: 'https://image.pollinations.ai/prompt/old%20button%20cell%20batteries?width=400&height=400&nologo=true', funFact: 'Kích thước bằng đồng xu nhưng chứa lượng kim loại bạc, kiềm có độc tính rất cao.'),
      WasteItemData(name: 'Pin điện thoại cũ', imagePath: 'https://image.pollinations.ai/prompt/swollen%20smartphone%20battery?width=400&height=400&nologo=true', funFact: 'Pin Lithium-ion khi bị phồng hoặc đâm thủng ở bãi rác có nguy cơ tự bốc cháy rất lớn.'),
      WasteItemData(name: 'Sạc dự phòng hỏng', imagePath: 'https://image.pollinations.ai/prompt/broken%20power%20bank?width=400&height=400&nologo=true', funFact: 'Thuộc nhóm rác điện tử e-waste nhạy cảm, có thể gây nổ hầm rác nếu bị kẹp ép.'),
      WasteItemData(name: 'Pin laptop', imagePath: 'https://image.pollinations.ai/prompt/old%20laptop%20battery?width=400&height=400&nologo=true', funFact: 'Chứa nhiều cell pin lithium nhỏ, phải được các công ty môi trường xử lý bóc tách riêng.'),
      WasteItemData(name: 'Ắc quy xe máy', imagePath: 'https://image.pollinations.ai/prompt/old%20motorcycle%20battery?width=400&height=400&nologo=true', funFact: 'Ắc quy chứa axit sunfuric và chì, gây phỏng da và hủy hoại đất đai nặng nề.'),
      WasteItemData(name: 'Ắc quy ô tô', imagePath: 'https://image.pollinations.ai/prompt/old%20car%20battery?width=400&height=400&nologo=true', funFact: 'Hầu hết ắc quy ô tô có thể được tái chế an toàn nếu mang đổi trả đúng trạm dịch vụ.'),
      WasteItemData(name: 'Đèn huỳnh quang dài', imagePath: 'https://image.pollinations.ai/prompt/broken%20fluorescent%20tube?width=400&height=400&nologo=true', funFact: 'Bên trong ống chứa bột thủy ngân vô cùng độc hại cho hệ thần kinh nếu bạn hít phải.'),
      WasteItemData(name: 'Bóng đèn compact', imagePath: 'https://image.pollinations.ai/prompt/broken%20compact%20fluorescent%20bulb?width=400&height=400&nologo=true', funFact: 'Cẩn thận khi gói ghém để bóng đèn không bị vỡ vụn khi vứt vào thùng rác nguy hại.'),
      WasteItemData(name: 'Bóng đèn sợi đốt', imagePath: 'https://image.pollinations.ai/prompt/burnt%20out%20incandescent%20bulb?width=400&height=400&nologo=true', funFact: 'Dù ít độc hơn compact, dây tóc vonfram mảnh bên trong vẫn cần xử lý cách ly.'),
      WasteItemData(name: 'Nhiệt kế thủy ngân', imagePath: 'https://image.pollinations.ai/prompt/broken%20mercury%20thermometer?width=400&height=400&nologo=true', funFact: 'Thủy ngân lỏng bốc hơi ở nhiệt độ phòng, gây suy thận và tổn thương não bộ.'),
      WasteItemData(name: 'Hộp thuốc hết hạn', imagePath: 'https://image.pollinations.ai/prompt/expired%20medicine%20bottles?width=400&height=400&nologo=true', funFact: 'Tuyệt đối không xả thuốc vào bồn cầu vì kháng sinh sẽ rò rỉ làm hỏng hệ thống nước ngầm.'),
      WasteItemData(name: 'Vỉ thuốc tây dở', imagePath: 'https://image.pollinations.ai/prompt/used%20blister%20pack%20pills?width=400&height=400&nologo=true', funFact: 'Vỏ nhôm trộn nhựa cộng dư lượng thuốc làm cho vỉ thuốc không thể phân loại tái chế thông thường.'),
      WasteItemData(name: 'Lọ thuốc ho', imagePath: 'https://image.pollinations.ai/prompt/expired%20cough%20syrup%20bottle?width=400&height=400&nologo=true', funFact: 'Dung dịch hóa dược dư thừa có thể gây ngộ độc cho động vật hoang dã bới rác.'),
      WasteItemData(name: 'Bình xịt muỗi', imagePath: 'https://image.pollinations.ai/prompt/empty%20bug%20spray%20can?width=400&height=400&nologo=true', funFact: 'Ngay cả khi dùng hết, khí nén dung môi bên trong vẫn là chất dễ phát nổ dưới nắng nóng.'),
      WasteItemData(name: 'Bình xịt gián', imagePath: 'https://image.pollinations.ai/prompt/empty%20roach%20killer%20spray?width=400&height=400&nologo=true', funFact: 'Chất diệt côn trùng là chất độc sinh học tàn phá vi sinh vật có lợi trong môi trường.'),
      WasteItemData(name: 'Bình gas mini', imagePath: 'https://image.pollinations.ai/prompt/empty%20butane%20gas%20canister?width=400&height=400&nologo=true', funFact: 'Nguy cơ cháy nổ kinh hoàng nếu xe ép rác nén vỡ bình gas còn sót khí bên trong.'),
      WasteItemData(name: 'Sơn tường thừa', imagePath: 'https://image.pollinations.ai/prompt/half%20empty%20paint%20bucket?width=400&height=400&nologo=true', funFact: 'Tuyệt đối không đổ sơn xuống cống rãnh vì mảng sơn sẽ bịt kín mang cá và diệt thủy sinh.'),
      WasteItemData(name: 'Lon sơn xịt', imagePath: 'https://image.pollinations.ai/prompt/empty%20spray%20paint%20can?width=400&height=400&nologo=true', funFact: 'Lớp sơn bám dính, cặn dung môi và khí nén khiến lon sơn xịt bị từ chối ở mọi xưởng tái chế kim loại.'),
      WasteItemData(name: 'Dung môi pha sơn', imagePath: 'https://image.pollinations.ai/prompt/paint%20thinner%20bottle?width=400&height=400&nologo=true', funFact: 'Thinner hay xăng thơm là hóa chất cực kỳ dễ bay hơi, gây cháy và nhiễm độc hô hấp.'),
      WasteItemData(name: 'Cọ sơn dính hóa chất', imagePath: 'https://image.pollinations.ai/prompt/paint%20brush%20covered%20in%20dry%20paint?width=400&height=400&nologo=true', funFact: 'Lông cọ cứng đơ ngậm đầy hóa chất tổng hợp cứng đầu, phải đưa vào lò đốt rác nguy hại.'),
      WasteItemData(name: 'Tẩy bồn cầu thừa', imagePath: 'https://image.pollinations.ai/prompt/toilet%20bowl%20cleaner%20bottle?width=400&height=400&nologo=true', funFact: 'Axit tẩy rửa nếu vô tình trộn lẫn với các rác thải hóa chất khác có thể sinh ra khí độc chlorine.'),
      WasteItemData(name: 'Hóa chất lau kính dư', imagePath: 'https://image.pollinations.ai/prompt/glass%20cleaner%20spray%20bottle?width=400&height=400&nologo=true', funFact: 'Chứa amoniac nồng độ cao làm thay đổi độ pH của hệ sinh thái nước.'),
      WasteItemData(name: 'Thuốc trừ sâu', imagePath: 'https://image.pollinations.ai/prompt/pesticide%20bottle%20empty?width=400&height=400&nologo=true', funFact: 'Bao bì nông dược luôn được quy định phải thu gom tại các bể chứa bê tông riêng ngoài đồng ruộng.'),
      WasteItemData(name: 'Thuốc diệt cỏ', imagePath: 'https://image.pollinations.ai/prompt/herbicide%20bottle?width=400&height=400&nologo=true', funFact: 'Chỉ một giọt rò rỉ cũng có thể làm chết thảm thực vật xung quanh bãi chôn lấp rác.'),
      WasteItemData(name: 'Bả chuột', imagePath: 'https://image.pollinations.ai/prompt/rat%20poison%20pellets?width=400&height=400&nologo=true', funFact: 'Cực kỳ độc đối với trẻ em, chó mèo hoặc chim chóc vô tình ăn phải bả vứt bừa bãi.'),
      WasteItemData(name: 'Keo dính chuột', imagePath: 'https://image.pollinations.ai/prompt/used%20mouse%20glue%20trap?width=400&height=400&nologo=true', funFact: 'Bề mặt keo dính chứa hóa chất dẫn dụ và máu động vật thối rữa, là mối nguy sinh học.'),
      WasteItemData(name: 'Keo 502 dư', imagePath: 'https://image.pollinations.ai/prompt/dry%20super%20glue%20bottle?width=400&height=400&nologo=true', funFact: 'Hơi keo Cyanoacrylate gây xé mắt và kích ứng đường hô hấp, lọ keo khô cứng hoàn toàn không tái chế được.'),
      WasteItemData(name: 'Keo silicon', imagePath: 'https://image.pollinations.ai/prompt/used%20silicone%20sealant%20tube?width=400&height=400&nologo=true', funFact: 'Chất liệu trét khe hở này chứa dung môi độc, vứt bỏ cần cẩn thận để không dính bết vào rác khác.'),
      WasteItemData(name: 'Mực in máy tính', imagePath: 'https://image.pollinations.ai/prompt/empty%20printer%20ink%20cartridge?width=400&height=400&nologo=true', funFact: 'Hộp mực chứa hóa chất phức tạp và thiết kế nhựa tinh vi, chỉ có thể nạp lại chứ khó đem đi băm tái chế.'),
      WasteItemData(name: 'Mực máy photo', imagePath: 'https://image.pollinations.ai/prompt/empty%20photocopier%20toner%20cartridge?width=400&height=400&nologo=true', funFact: 'Bụi bột mực laser siêu mịn có thể bay thẳng vào màng phổi gây ung thư cho thợ xử lý rác.'),
      WasteItemData(name: 'Nhớt xe máy thải', imagePath: 'https://image.pollinations.ai/prompt/bottle%20of%20used%20motor%20oil?width=400&height=400&nologo=true', funFact: 'Đổ 1 lít dầu nhớt thải ra đất sẽ làm mất khả năng tự lọc của 1 triệu lít nước ngọt ngầm.'),
      WasteItemData(name: 'Dầu phanh xe', imagePath: 'https://image.pollinations.ai/prompt/brake%20fluid%20bottle?width=400&height=400&nologo=true', funFact: 'Hóa chất phanh có tính ăn mòn khủng khiếp, làm bong tróc sơn và ăn mòn da tay trần.'),
      WasteItemData(name: 'Nước làm mát', imagePath: 'https://image.pollinations.ai/prompt/engine%20coolant%20jug?width=400&height=400&nologo=true', funFact: 'Chất ethylene glycol có màu xanh và vị ngọt, gây tử vong cho thú cưng chó mèo nếu chúng liếm phải.'),
      WasteItemData(name: 'Giẻ lau dầu máy', imagePath: 'https://image.pollinations.ai/prompt/dirty%20oily%20shop%20rag?width=400&height=400&nologo=true', funFact: 'Giẻ ngâm dầu công nghiệp được xếp vào chất thải nguy hại lây nhiễm, dễ tự bốc cháy trong kho kín.'),
      WasteItemData(name: 'Tụ điện hỏng', imagePath: 'https://image.pollinations.ai/prompt/burnt%20electronic%20capacitor?width=400&height=400&nologo=true', funFact: 'Tụ máy bơm đời cũ có thể rò rỉ dầu hoặc hợp chất PCB cực độc, chất gây ung thư cấm sử dụng toàn cầu.'),
      WasteItemData(name: 'Bo mạch điện tử', imagePath: 'https://image.pollinations.ai/prompt/broken%20green%20circuit%20board?width=400&height=400&nologo=true', funFact: 'Mạch in chứa hỗn hợp kim loại nặng như chì dán linh kiện, cadmium và thiếc.'),
      WasteItemData(name: 'Điện thoại đập đá', imagePath: 'https://image.pollinations.ai/prompt/broken%20old%20keypad%20phone?width=400&height=400&nologo=true', funFact: 'Màn hình LCD và pin điện thoại cũ rỉ sét rò rỉ hóa chất độc ra rác sinh hoạt.'),
      WasteItemData(name: 'Tai nghe hỏng', imagePath: 'https://image.pollinations.ai/prompt/tangled%20broken%20earphones?width=400&height=400&nologo=true', funFact: 'Tai nghe không dây chứa pin siêu nhỏ, vứt sai cách là ẩn họa cháy nổ trạm tập kết rác.'),
      WasteItemData(name: 'Củ sạc cháy', imagePath: 'https://image.pollinations.ai/prompt/burnt%20phone%20charger%20adapter?width=400&height=400&nologo=true', funFact: 'Nhựa cháy, mảng tụ điện hóa và cuộn cảm bên trong củ sạc biến nó thành rác điện tử độc hại.'),
      WasteItemData(name: 'Cáp sạc đứt', imagePath: 'https://image.pollinations.ai/prompt/frayed%20charging%20cable?width=400&height=400&nologo=true', funFact: 'Lớp nhựa bọc cáp chứa chất chống cháy halogen, sinh ra khí Dioxin khét lẹt khi đốt ở nhiệt độ thấp.'),
      WasteItemData(name: 'Nước hoa quá hạn', imagePath: 'https://image.pollinations.ai/prompt/old%20perfume%20bottle?width=400&height=400&nologo=true', funFact: 'Cồn và dung môi hương liệu nồng độ cao có tính chất bắt lửa cực kì dễ dàng.'),
      WasteItemData(name: 'Thuốc nhuộm tóc', imagePath: 'https://image.pollinations.ai/prompt/hair%20dye%20tube%20used?width=400&height=400&nologo=true', funFact: 'Ammonia và peroxide trong tuýp thuốc nhuộm diệt sạch các vi sinh vật yếu ớt ngoài môi trường.'),
      WasteItemData(name: 'Sơn móng tay', imagePath: 'https://image.pollinations.ai/prompt/dry%20nail%20polish%20bottle?width=400&height=400&nologo=true', funFact: 'Dung môi bay hơi (VOCs) trong sơn móng tay gây ô nhiễm không khí và ngộ độc hệ sinh thái.'),
      WasteItemData(name: 'Axeton tẩy móng', imagePath: 'https://image.pollinations.ai/prompt/acetone%20nail%20polish%20remover%20bottle?width=400&height=400&nologo=true', funFact: 'Dung môi công nghiệp dễ bắt lửa, tuyệt đối không đổ trực tiếp vào cống thoát nước nhà vệ sinh.'),
      WasteItemData(name: 'Kim tiêm y tế', imagePath: 'https://image.pollinations.ai/prompt/used%20medical%20syringe?width=400&height=400&nologo=true', funFact: 'Nguy cơ đâm thủng tay và lây nhiễm HIV/Viêm gan cho công nhân vệ sinh, phải bỏ vào bình nhựa cứng.'),
      WasteItemData(name: 'Dao mổ y tế', imagePath: 'https://image.pollinations.ai/prompt/used%20surgical%20scalpel?width=400&height=400&nologo=true', funFact: 'Rác thải sắc nhọn lây nhiễm sinh học, xử lý lỏng lẻo sẽ vi phạm nghiêm trọng luật môi trường.'),
      WasteItemData(name: 'Băng gạc máu', imagePath: 'https://image.pollinations.ai/prompt/bloody%20medical%20gauze?width=400&height=400&nologo=true', funFact: 'Chất thải y tế mang mầm bệnh, cần được tập kết riêng trong túi nilon y tế màu vàng chuẩn.'),
      WasteItemData(name: 'Cảm biến khói', imagePath: 'https://image.pollinations.ai/prompt/old%20smoke%20detector?width=400&height=400&nologo=true', funFact: 'Nhiều cảm biến khói đời cũ sử dụng một lượng nhỏ chất phóng xạ Americium-241, rất nhạy cảm.'),
    ],
    WasteCategory.trash: [
      WasteItemData(name: 'Ly giấy cà phê', imagePath: 'https://image.pollinations.ai/prompt/dirty%20paper%20coffee%20cup?width=400&height=400&nologo=true', funFact: 'Màng PE chống thấm nước dán chặt bên trong ly giấy khiến giấy này không thể bị làm nhuyễn tái chế.'),
      WasteItemData(name: 'Ống hút nhựa', imagePath: 'https://image.pollinations.ai/prompt/used%20plastic%20straws?width=400&height=400&nologo=true', funFact: 'Kích thước nhỏ và nhẹ khiến ống hút lọt qua các mắt lưới phân loại ở nhà máy tái chế, cuối cùng đổ ra đại dương.'),
      WasteItemData(name: 'Muỗng nhựa 1 lần', imagePath: 'https://image.pollinations.ai/prompt/dirty%20plastic%20spoon?width=400&height=400&nologo=true', funFact: 'Được làm từ nhựa Polystyrene chất lượng rất thấp, giòn vỡ và chi phí tái chế còn đắt hơn sản xuất mới.'),
      WasteItemData(name: 'Nĩa nhựa 1 lần', imagePath: 'https://image.pollinations.ai/prompt/dirty%20plastic%20fork?width=400&height=400&nologo=true', funFact: 'Dính đầy dầu mỡ thức ăn, các vật dụng ăn uống này mặc định là rác chôn lấp.'),
      WasteItemData(name: 'Đũa tre 1 lần', imagePath: 'https://image.pollinations.ai/prompt/used%20bamboo%20chopsticks?width=400&height=400&nologo=true', funFact: 'Đũa tre ngậm hóa chất lưu huỳnh tẩy trắng và nước bọt, không an toàn để ủ phân bón hữu cơ.'),
      WasteItemData(name: 'Hộp xốp cơm', imagePath: 'https://image.pollinations.ai/prompt/dirty%20styrofoam%20food%20box?width=400&height=400&nologo=true', funFact: 'Xốp EPS dính nước thịt xốt không có nhà máy nào nhận tái chế, chúng nổi lềnh bềnh ngàn năm trên biển.'),
      WasteItemData(name: 'Túi nilon mỏng', imagePath: 'https://image.pollinations.ai/prompt/flimsy%20plastic%20shopping%20bag?width=400&height=400&nologo=true', funFact: 'Túi rác chợ mỏng dính thường xuyên quấn kẹt vào các trục quay của máy nghiền rác tái chế làm hỏng máy.'),
      WasteItemData(name: 'Khẩu trang y tế', imagePath: 'https://image.pollinations.ai/prompt/used%20blue%20medical%20mask?width=400&height=400&nologo=true', funFact: 'Khẩu trang thực chất dệt từ sợi nhựa vi mô (Polypropylene), cần cắt dây thun vứt chôn lấp để chim chóc không bị vướng.'),
      WasteItemData(name: 'Khẩu trang vải', imagePath: 'https://image.pollinations.ai/prompt/dirty%20cloth%20face%20mask?width=400&height=400&nologo=true', funFact: 'Vải bám mồ hôi, dính bụi bẩn và sợi thun co giãn không có khả năng tái sử dụng.'),
      WasteItemData(name: 'Tã giấy trẻ em', imagePath: 'https://image.pollinations.ai/prompt/dirty%20baby%20diaper?width=400&height=400&nologo=true', funFact: 'Hạt gel siêu thấm, nhựa nilon và chất thải con người khiến bỉm tã mất từ 250 đến 500 năm mới phân hủy hết.'),
      WasteItemData(name: 'Băng vệ sinh', imagePath: 'https://image.pollinations.ai/prompt/used%20sanitary%20pad%20wrapped?width=400&height=400&nologo=true', funFact: 'Rác thải vệ sinh cá nhân luôn phải được cuộn kín bọc nilon rồi đem đi xử lý chôn lấp/đốt tiêu hủy.'),
      WasteItemData(name: 'Giấy vệ sinh dùng', imagePath: 'https://image.pollinations.ai/prompt/crumpled%20used%20toilet%20paper?width=400&height=400&nologo=true', funFact: 'Khác với giấy báo, giấy vệ sinh có sợi giấy cực ngắn để dễ rã trong bồn cầu, vứt ra ngoài là rác bẩn.'),
      WasteItemData(name: 'Khăn ướt đã dùng', imagePath: 'https://image.pollinations.ai/prompt/used%20wet%20wipes?width=400&height=400&nologo=true', funFact: 'Trông như giấy nhưng khăn ướt phần lớn đan từ nhựa polyester, vứt bồn cầu sẽ gây tắc cống kinh hoàng.'),
      WasteItemData(name: 'Bông tẩy trang', imagePath: 'https://image.pollinations.ai/prompt/dirty%20cotton%20makeup%20pads?width=400&height=400&nologo=true', funFact: 'Dính mỹ phẩm hóa học và dung môi tẩy rửa, bông gòn này không ủ rác hữu cơ được.'),
      WasteItemData(name: 'Tăm bông tai', imagePath: 'https://image.pollinations.ai/prompt/used%20cotton%20swabs?width=400&height=400&nologo=true', funFact: 'Ống nhựa que tăm bông là một trong những loại rác biển tìm thấy nhiều nhất trên các bãi cát.'),
      WasteItemData(name: 'Băng keo trong', imagePath: 'https://image.pollinations.ai/prompt/crumpled%20clear%20packing%20tape?width=400&height=400&nologo=true', funFact: 'Lớp keo hóa học dính bết làm kẹt máy móc, bọc nhựa BOPP thì không tự rã trong tự nhiên.'),
      WasteItemData(name: 'Băng keo hai mặt', imagePath: 'https://image.pollinations.ai/prompt/used%20double%20sided%20tape?width=400&height=400&nologo=true', funFact: 'Cấu tạo phức tạp gồm giấy tẩm silicon và lớp màng keo dính hai bên bóc không rạch ròi ra được.'),
      WasteItemData(name: 'Decal dán lỗi', imagePath: 'https://image.pollinations.ai/prompt/peeled%20stickers%20decal?width=400&height=400&nologo=true', funFact: 'Mặt keo dính đằng sau khiến tem nhãn decal không thể tái chế chung với giấy văn phòng.'),
      WasteItemData(name: 'Túi snack', imagePath: 'https://image.pollinations.ai/prompt/empty%20potato%20chips%20bag?width=400&height=400&nologo=true', funFact: 'Lớp màng nhôm óng ánh ép chặt với lớp vỏ nhựa nilon không thể tách rời để tái chế theo cách thông thường.'),
      WasteItemData(name: 'Vỏ kẹo mút', imagePath: 'https://image.pollinations.ai/prompt/empty%20lollipop%20wrapper?width=400&height=400&nologo=true', funFact: 'Những mẩu nilon nhỏ vụn vặt thế này gây cực kỳ nhiều khó khăn và tốn công cho việc nhặt nhạnh tái chế.'),
      WasteItemData(name: 'Vỏ kẹo cao su', imagePath: 'https://image.pollinations.ai/prompt/chewing%20gum%20foil%20wrapper?width=400&height=400&nologo=true', funFact: 'Mảnh giấy bạc bọc kẹo dính đầy mùi kẹo và nhỏ xíu nên không có vựa phế liệu nào thu mua.'),
      WasteItemData(name: 'Bã kẹo cao su', imagePath: 'https://image.pollinations.ai/prompt/chewed%20gum%20wad?width=400&height=400&nologo=true', funFact: 'Ít ai biết bã kẹo cao su hiện đại làm từ cao su tổng hợp gốc dầu mỏ (nhựa), chúng hoàn toàn không phân hủy.'),
      WasteItemData(name: 'Tàn thuốc lá', imagePath: 'https://image.pollinations.ai/prompt/cigarette%20ashes%20and%20buds?width=400&height=400&nologo=true', funFact: 'Chứa hàng ngàn hóa chất độc hại sinh ra từ quá trình đốt cháy, gây ngộ độc đất.'),
      WasteItemData(name: 'Đầu lọc thuốc lá', imagePath: 'https://image.pollinations.ai/prompt/cigarette%20butts%20waste?width=400&height=400&nologo=true', funFact: 'Trông như bông nhưng đầu lọc làm từ cellulose acetate, một loại nhựa mất 10 năm để vỡ vụn thành vi nhựa.'),
      WasteItemData(name: 'Đồ gốm vỡ', imagePath: 'https://image.pollinations.ai/prompt/broken%20ceramic%20bowl?width=400&height=400&nologo=true', funFact: 'Gốm sứ đã bị nung chín ở nhiệt độ ngàn độ C, không thể nung chảy để đúc lại như thủy tinh.'),
      WasteItemData(name: 'Bát sứ mẻ', imagePath: 'https://image.pollinations.ai/prompt/chipped%20porcelain%20bowl?width=400&height=400&nologo=true', funFact: 'Hãy bọc kín mảnh vỡ bằng giấy báo, dán băng keo ghi "mảnh vỡ sắc nhọn" để bảo vệ người nhặt rác.'),
      WasteItemData(name: 'Thủy tinh chịu nhiệt', imagePath: 'https://image.pollinations.ai/prompt/broken%20pyrex%20glass%20dish?width=400&height=400&nologo=true', funFact: 'Đồ thủy tinh Pyrex/chịu nhiệt lò vi sóng có điểm nóng chảy cao hơn hẳn chai lọ bình thường, trộn vào tái chế sẽ làm hỏng cả lò đúc.'),
      WasteItemData(name: 'Gương vỡ', imagePath: 'https://image.pollinations.ai/prompt/broken%20mirror%20shards?width=400&height=400&nologo=true', funFact: 'Lớp hóa chất tráng bạc mặt sau gương khiến tấm thủy tinh này không còn tinh khiết để tái chế được nữa.'),
      WasteItemData(name: 'Kính cận gãy', imagePath: 'https://image.pollinations.ai/prompt/broken%20eyeglasses?width=400&height=400&nologo=true', funFact: 'Tròng kính quang học pha nhựa đặc biệt và gọng phức tạp khiến nó không thể chui vào máy tái chế nhựa.'),
      WasteItemData(name: 'Quần áo rách nát', imagePath: 'https://image.pollinations.ai/prompt/torn%20dirty%20clothes%20rag?width=400&height=400&nologo=true', funFact: 'Vải dệt tổng hợp (polyester) dính mốc rách nát chỉ có thể đi thẳng ra bãi chôn lấp rác thải sinh hoạt.'),
      WasteItemData(name: 'Đồ lót rách', imagePath: 'https://image.pollinations.ai/prompt/torn%20underwear%20waste?width=400&height=400&nologo=true', funFact: 'Quần áo lót cũ kỹ thuộc loại rác thải vệ sinh cá nhân, không nên quyên góp hay tái chế.'),
      WasteItemData(name: 'Giày da hỏng', imagePath: 'https://image.pollinations.ai/prompt/old%20torn%20leather%20shoe?width=400&height=400&nologo=true', funFact: 'Keo dán công nghiệp, đế cao su, vải lót và da PU kết dính chặt chẽ không thể tách rời bằng máy móc.'),
      WasteItemData(name: 'Dép lào đứt', imagePath: 'https://image.pollinations.ai/prompt/broken%20flip%20flops?width=400&height=400&nologo=true', funFact: 'Đế xốp xẹp lún ngấm đầy mồ hôi chân và đất cát vĩnh viễn không được tái chế.'),
      WasteItemData(name: 'Tất (vớ) thủng', imagePath: 'https://image.pollinations.ai/prompt/socks%20with%20holes%20waste?width=400&height=400&nologo=true', funFact: 'Độ co giãn dẻo dai của sợi spandex trong tất cản trở mọi nỗ lực nghiền nát vải dệt rác.'),
      WasteItemData(name: 'Thú bông nát', imagePath: 'https://image.pollinations.ai/prompt/torn%20old%20teddy%20bear?width=400&height=400&nologo=true', funFact: 'Bông nhồi polyester bên trong dễ ẩm mốc và mang theo vi khuẩn mạt bụi sừng sững cùng năm tháng.'),
      WasteItemData(name: 'Hoa nhựa phai màu', imagePath: 'https://image.pollinations.ai/prompt/faded%20artificial%20plastic%20flowers?width=400&height=400&nologo=true', funFact: 'Cành hoa cắm kẽm kim loại bọc nhựa nhuộm màu xanh đỏ rực rỡ khiến hệ thống máy phân tách bó tay.'),
      WasteItemData(name: 'Đồ chơi nhựa tạp', imagePath: 'https://image.pollinations.ai/prompt/broken%20cheap%20plastic%20toys?width=400&height=400&nologo=true', funFact: 'Đồ chơi rẻ tiền làm từ nhựa hỗn hợp pha tạp chất vô danh, không vựa phế liệu nào rước.'),
      WasteItemData(name: 'Bàn chải đánh răng', imagePath: 'https://image.pollinations.ai/prompt/old%20used%20toothbrush?width=400&height=400&nologo=true', funFact: 'Cán nhựa cứng ngắc kết hợp lông nylon tơ mềm cắm chặt làm nó không thể tách riêng để tái chế rác nhựa.'),
      WasteItemData(name: 'Bọt biển rửa bát', imagePath: 'https://image.pollinations.ai/prompt/dirty%20kitchen%20sponge?width=400&height=400&nologo=true', funFact: 'Nhựa xốp Polyurethane này là một mớ hỗn độn chứa đầy vi khuẩn xà phòng hôi thối.'),
      WasteItemData(name: 'Cọ xoong gỉ', imagePath: 'https://image.pollinations.ai/prompt/rusty%20steel%20wool%20scrubber?width=400&height=400&nologo=true', funFact: 'Búi sắt cọ nồi mủn nát rỉ sét lẫn đầy cặn thức ăn mỡ màng, vứt luôn đi chứ giữ làm chi.'),
      WasteItemData(name: 'Dao cạo râu nhựa', imagePath: 'https://image.pollinations.ai/prompt/used%20disposable%20razor?width=400&height=400&nologo=true', funFact: 'Lưỡi dao lam bằng thép đúc ngầm chặt trong cán nhựa mỏng dính, rất rủi ro đứt tay cho thợ bới rác.'),
      WasteItemData(name: 'Cát vệ sinh mèo', imagePath: 'https://image.pollinations.ai/prompt/used%20cat%20litter%20waste?width=400&height=400&nologo=true', funFact: 'Chứa mầm bệnh ký sinh trùng Toxoplasma cực độc hại, cần gói nilon riêng kín rịt và cho vào bãi chôn.'),
      WasteItemData(name: 'Phân chó (trong túi)', imagePath: 'https://image.pollinations.ai/prompt/dog%20poop%20in%20plastic%20bag?width=400&height=400&nologo=true', funFact: 'Không bao giờ ủ phân thú cưng ăn thịt chung với rác hữu cơ trồng rau ăn lá vì mầm giun sán.'),
      WasteItemData(name: 'Tóc rụng', imagePath: 'https://image.pollinations.ai/prompt/clump%20of%20hair%20waste?width=400&height=400&nologo=true', funFact: 'Tóc dệt nên từ protein cực dai, nó không rã ra mà quấn thắt vào trục máy tái chế gây cháy motor máy băm.'),
      WasteItemData(name: 'Bụi quét nhà', imagePath: 'https://image.pollinations.ai/prompt/dustpan%20full%20of%20dirt%20and%20dust?width=400&height=400&nologo=true', funFact: 'Đống vụn quét nhà là hỗn hợp da chết, đất cát, lông thú, vi nhựa quần áo bay lơ lửng.'),
      WasteItemData(name: 'Gói hút ẩm', imagePath: 'https://image.pollinations.ai/prompt/silica%20gel%20packets?width=400&height=400&nologo=true', funFact: 'Hạt silica gel bên trong không có tính độc hại nhưng nó trơ như đá tảng, không tự rã tự nhiên hay tái chế.'),
      WasteItemData(name: 'Giấy nến lót bánh', imagePath: 'https://image.pollinations.ai/prompt/used%20baking%20parchment%20paper?width=400&height=400&nologo=true', funFact: 'Lớp giấy nướng bọc silicone chống dính vĩnh viễn không bao giờ ngấm nước để làm bột giấy tái sinh được.'),
      WasteItemData(name: 'Nắp ly màng ép', imagePath: 'https://image.pollinations.ai/prompt/torn%20boba%20tea%20plastic%20film%20lid?width=400&height=400&nologo=true', funFact: 'Màng nilon ép nhiệt mỏng như tờ giấy dán chặt lên viền ly dính đầy đường, hoàn toàn vô dụng tái chế.'),
      WasteItemData(name: 'Túi rác nilon đen', imagePath: 'https://image.pollinations.ai/prompt/black%20plastic%20garbage%20bag?width=400&height=400&nologo=true', funFact: 'Bản thân cái túi nilon đen to tướng này cũng là nhựa tái sinh cấp bét (cấp độ cuối) bốc mùi hôi, chỉ chôn hoặc đốt.'),
      WasteItemData(name: 'Dây chun (Thun)', imagePath: 'https://image.pollinations.ai/prompt/broken%20rubber%20bands?width=400&height=400&nologo=true', funFact: 'Sợi cao su sẽ đứt vụn, mủn rã chảy dính sau một thời gian, không có bất kỳ giá trị tái thu hồi nào.'),
    ],
  };

  late final List<GameQuestion> _questions;
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _streak = 0;
  int _timeLeft = 15;
  int _round = 1;
  int _roundScore = 0;
  bool _isAnswerLocked = false;
  Timer? _timer;

  static const int _questionTimeLimit = 15;
  static const int _questionsPerRound = 200;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(_questionsPerRound);
    _startTimer();
  }

  List<GameQuestion> _generateQuestions(int count) {
    final random = Random();
    final categories = WasteCategory.values;
    final generated = <GameQuestion>[];

    for (var i = 0; i < count; i++) {
      final category = categories[random.nextInt(categories.length)];
      final itemsForCategory = _wasteDatabase[category]!;

      // Random chọn 1 object (chứa sẵn Tên, Ảnh, Fact đúng chuẩn của nó)
      final selectedItem = itemsForCategory[random.nextInt(itemsForCategory.length)];

      generated.add(
        GameQuestion(
          name: selectedItem.name,
          imagePath: selectedItem.imagePath,
          correctCategory: category,
          funFact: selectedItem.funFact,
        ),
      );
    }

    return generated;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _questionTimeLimit);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isAnswerLocked) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        _onTimeUp();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _onTimeUp() {
    if (_isAnswerLocked) return;
    _isAnswerLocked = true;
    _streak = 0;
    _showFeedback(
      false,
      'Hết thời gian! ${_questions[_currentIndex].name} thuộc nhóm "${_labelForCategory(_questions[_currentIndex].correctCategory)}".',
    );
  }

  String _labelForCategory(WasteCategory category) {
    switch (category) {
      case WasteCategory.recyclable:
        return 'Tái chế';
      case WasteCategory.organic:
        return 'Hữu cơ';
      case WasteCategory.hazardous:
        return 'Nguy hại';
      case WasteCategory.trash:
        return 'Thông thường';
    }
  }

  void _checkAnswer(WasteCategory selected, GameProvider provider) {
    if (_isAnswerLocked) return;
    _isAnswerLocked = true;
    _timer?.cancel();
    final isCorrect = selected == _questions[_currentIndex].correctCategory;

    if (isCorrect) {
      _correctAnswers++;
      _streak++;
      final bonus = _streak >= 3 ? 5 : 0;
      final gained = 10 + bonus;
      _roundScore += gained;
      provider.addScore(gained);
      _showFeedback(true, _questions[_currentIndex].funFact);
    } else {
      _streak = 0;
      _showFeedback(
        false,
        'Sai rồi! Đáp án đúng là "${_labelForCategory(_questions[_currentIndex].correctCategory)}".',
      );
    }
  }

  void _showFeedback(bool isCorrect, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Icon(
          isCorrect ? Icons.check_circle_outline : Icons.error_outline,
          color: isCorrect ? Colors.green : Colors.red,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect ? "Chính xác! +${_streak >= 3 ? 15 : 10} điểm" : "Rất tiếc!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (isCorrect && _streak >= 3) ...[
              const SizedBox(height: 8),
              const Text(
                'Combo Streak! +5 điểm thưởng',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = (_currentIndex + 1) % _questions.length;
                _isAnswerLocked = false;
              });
              if (_currentIndex == 0) {
                _round++;
              }
              _startTimer();
            },
            child: const Text("Tiếp tục"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final progress = (_currentIndex + 1) / _questions.length;
    final timerRatio = _timeLeft / _questionTimeLimit;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.045).clamp(12.0, 24.0);
    final sectionGap = (screenWidth * 0.045).clamp(12.0, 20.0);
    final titleSize = (screenWidth * 0.05).clamp(16.0, 24.0);
    final scoreSize = (screenWidth * 0.043).clamp(14.0, 18.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử thách Phân loại Pro'),
        actions: [
          IconButton(
            tooltip: 'Kho huy hiệu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgeInventoryScreen()),
              );
            },
            icon: const Icon(Icons.workspace_premium_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Điểm: ${gameProvider.score}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: scoreSize),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: sectionGap),
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 0),
            padding: EdgeInsets.all((screenWidth * 0.035).clamp(10.0, 16.0)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A7B24), Color(0xFF36A844)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular((screenWidth * 0.05).clamp(14.0, 20.0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _statChip(Icons.local_fire_department_rounded, 'Streak', 'x$_streak'),
                    const SizedBox(width: 8),
                    _statChip(Icons.verified_rounded, 'Đúng', '$_correctAnswers'),
                    const SizedBox(width: 8),
                    _statChip(Icons.flag_rounded, 'Vòng', '$_round'),
                  ],
                ),
                SizedBox(height: (screenWidth * 0.025).clamp(8.0, 12.0)),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress.clamp(0, 1),
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: (screenWidth * 0.03).clamp(8.0, 14.0)),
                    Text(
                      '${_currentIndex + 1}/${_questions.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: (screenWidth * 0.036).clamp(12.0, 15.0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (screenWidth * 0.025).clamp(8.0, 12.0)),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Thời gian còn lại: ${_timeLeft}s',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: timerRatio.clamp(0, 1),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: sectionGap),
          if (gameProvider.earnedBadges.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: gameProvider.earnedBadges.map((badgeName) {
                    final icon = gameProvider.badgeIcons[badgeName] ?? '🏅';
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '$icon $badgeName',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          SizedBox(height: (sectionGap * 0.8)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: WasteCard(question: _questions[_currentIndex]),
          ),
          SizedBox(height: sectionGap),
          Text(
            "Đây là loại rác nào?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: titleSize * 0.78, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: (screenWidth * 0.015).clamp(4.0, 8.0)),
          Text(
            _questions[_currentIndex].name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: sectionGap),
          _buildActionButtons(gameProvider),
          Padding(
            padding: EdgeInsets.only(top: sectionGap),
            child: Text(
              'Điểm vòng hiện tại: $_roundScore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: (screenWidth * 0.037).clamp(12.0, 15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '$label: $value',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.06).clamp(14.0, 30.0);
    final gap = (screenWidth * 0.04).clamp(10.0, 18.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _gameButton("Tái chế", Colors.blue, () => _checkAnswer(WasteCategory.recyclable, provider))),
              SizedBox(width: gap),
              Expanded(child: _gameButton("Hữu cơ", Colors.brown, () => _checkAnswer(WasteCategory.organic, provider))),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(child: _gameButton("Nguy hại", Colors.red, () => _checkAnswer(WasteCategory.hazardous, provider))),
              SizedBox(width: gap),
              Expanded(child: _gameButton("Thông thường", Colors.grey, () => _checkAnswer(WasteCategory.trash, provider))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameButton(String label, Color color, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalPadding = (screenWidth * 0.048).clamp(12.0, 20.0);
    final fontSize = (screenWidth * 0.043).clamp(14.0, 17.0);
    final radius = (screenWidth * 0.05).clamp(14.0, 20.0);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700)),
    );
  }
}