import 'package:flutter/material.dart';

class ScreenTopicDetail extends StatelessWidget {
  const ScreenTopicDetail({super.key});

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFF6F6F8);
    const primary = Color(0xFF135BEC);
    const textPrimary = Color(0xFF111318);
    const textMuted = Color(0xFF616F89);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: textPrimary), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: const Text('Topic Detail', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: textPrimary))],
      ),
      body: ListView(
        children: const [
          _PostBlock(),
          _CommentsSection(),
        ],
      ),
      bottomNavigationBar: const _CommentInput(),
    );
  }
}

class _PostBlock extends StatelessWidget {
  const _PostBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network('https://lh3.googleusercontent.com/aida-public/AB6AXuBziTFDoKi5rjlCyWlf_iqL_WNguoZ4J4Gfc5yrugPNPmdUG6svk0YctRGlpXbo4zzmTBFe8hcMsL2n5DsPf6cINyEZTOyavdXr_lVdZx0WFJmzpOfwgWZ1DnT7o0xoq1dPU3a_voBhsr3o2rn47iI0XP7t9wIIzmQF7qBm_sXFiEWRBnkaZsszWcjuWkCsbAMP8YwXmQ8H2h7EjXRjWaqJuW3wxWO9B-LqxB5GkP5TD3OzqaSbCYECWrQXz9lixa6bz_2iKloHmYw', width: 40, height: 40, fit: BoxFit.cover)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(children: [
              const Text('Dr. Minh Anh', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(color: const Color(0x33135BEC), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: const Text('Expert', style: TextStyle(color: Color(0xFF135BEC), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        const Text('2 hours ago', style: TextStyle(color: Color(0xFF616F89), fontSize: 12)),
        const SizedBox(height: 12),
        const Text('How to differentiate the symptoms of a mild stroke?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "I'm a general practitioner and I often find it hard to distinguish the early signs of a mild stroke from symptoms of general fatigue or other minor neurological issues. What are the key indicators we should look for that strongly suggest a mild stroke over other conditions? Any advice on quick assessment techniques would be greatly appreciated.",
          style: TextStyle(color: Color(0xFF374151)),
        ),
        const SizedBox(height: 12),
        const Divider(),
        Row(children: const [
          Icon(Icons.thumb_up, color: Color(0xFF616F89)),
          SizedBox(width: 6),
          Text('15', style: TextStyle(color: Color(0xFF616F89))),
          SizedBox(width: 16),
          Icon(Icons.mode_comment, color: Color(0xFF616F89)),
          SizedBox(width: 6),
          Text('3', style: TextStyle(color: Color(0xFF616F89))),
        ]),
      ]),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text('Comments (3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      _CommentItem(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAVcwQzH159qljPz9orBIfQocqXP_ZuKb8Dm3ecgTg7cDYJkCdNbwp7LstizUn3wdIhnCL9jqCdldqKDp4dj-9mzBMKWh3c0NciWRyc714bP0oXc5efGbVc5x0K86Mp4MYQc-_lw0G-fwbNj8_bAmvzJlnWi31ORGig3KXpnzl-cRwRgaf32V61I7StToDIA4ir3zmzwtR7dQlcc3uBu5rv4PvJyv0DbN050WljPHBvM6DnFssU4LrVwvVSjoDDguuq4_YswLgxS5Q',
        name: 'Nguyen Van B',
        time: '1 hour ago',
        text: "Great question! I'm also looking forward to an expert's answer on this.",
      ),
      _ReplyItem(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAL9vtxYi6X3oJkPCoHo3Qi-g9iPnNRXvFD3vZiY_Pmpa5zhkRTFe63D7EibSRcplZPxaSJ4cRJHwrWnVj40U2_Ckiec7sJv5fwVETwgPmBMtldZ9OI8STzc42cF_eVCYZzFEo02pFPJy6AWyWUBSnul4Ty7G9dz5l4Qkl5JwFCQI0SGUCECkWWu2Dp-xw47zzUEU_8LN2CK2VI_zKLjahbXAex4vAhOfiUgx_6WO7ESM5msLBzCvYar_RsaKTVSyvqSKAWFlo1Hf4',
        name: 'Tran Thi C',
        time: '45 minutes ago',
        text: 'My father experienced something similar. The key was the sudden onset of numbness on one side, which was different from his usual tiredness.',
      ),
      _CommentItem(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBnZGFGoin4uyYwJtc2-Oe8_1Y9kIT60T5Ht2mQQg_EBNEixvlfGcRGpAcZyCGcrpk69JRFCaaJtFzQwvspdu_DnVVYuqsoDJ84GcUGWRcbGrmfSOTZyMrUDb42Xe6BQUvwcKgNzdPmWNjJXusuSxWjxJNzHW3C0NKyf-Owc06m8jVFCjUyYTbMQlWtFTki8sQFXx7MNn7FObCpctI0r0SAGa-SmF7zPY3DlDqzBQbSqjEiLkU3GAV8Nkce8PsxyzmD8kOLHpiZwAs',
        name: 'Dr. Sarah',
        badge: 'Expert',
        time: '30 minutes ago',
        text: "Look for the FAST acronym: Face drooping, Arm weakness, Speech difficulty, Time to call emergency services. Even mild, sudden onset of these symptoms is a major red flag that shouldn't be mistaken for fatigue.",
      ),
    ]);
  }
}

class _CommentItem extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String time;
  final String text;
  final String? badge;
  const _CommentItem({required this.avatarUrl, required this.name, required this.time, required this.text, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(avatarUrl, width: 40, height: 40, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (badge != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0x33135BEC), borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(badge!, style: const TextStyle(color: Color(0xFF135BEC), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
            Text(time, style: const TextStyle(color: Color(0xFF616F89), fontSize: 12)),
            const SizedBox(height: 6),
            Text(text),
            const SizedBox(height: 6),
            Row(children: const [
              Icon(Icons.thumb_up, color: Color(0xFF616F89)),
              SizedBox(width: 12),
              Icon(Icons.thumb_down, color: Color(0xFF616F89)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ReplyItem extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String time;
  final String text;
  const _ReplyItem({required this.avatarUrl, required this.name, required this.time, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: _CommentItem(avatarUrl: avatarUrl, name: name, time: time, text: text),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Write your comment...',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          height: 40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135BEC), shape: const CircleBorder(), padding: EdgeInsets.zero),
            onPressed: () {},
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
